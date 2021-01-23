defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Config
  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.History
  alias Flexflow.TaskSupervisor
  alias Flexflow.Telemetry
  alias Flexflow.Transition
  alias Flexflow.Util

  @states [:created, :active, :loop, :waiting, :paused]

  @typedoc """
  Process state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name() | nil,
          id: Flexflow.id() | nil,
          events: Flexflow.events(),
          transitions: Flexflow.transitions(),
          state: state(),
          __args__: Flexflow.process_args(),
          __opts__: keyword(),
          __context__: Context.t(),
          __histories__: [History.t()],
          __definitions__: [definition],
          __graphviz__: keyword(),
          __loop_counter__: integer(),
          __counter__: integer(),
          __tasks__: %{reference() => term()}
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type definition :: {:event | :transition, Flexflow.key_normalize()}
  @type handle_cast_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_info_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_continue_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_call_return ::
          {:reply, term, t()}
          | {:noreply, term}
          | {:stop, term, term}
          | {:stop, term, term, t()}

  @enforce_keys [:module, :events, :transitions, :__definitions__]
  # @derive {Inspect, except: [:__definitions__, :__graphviz__]}
  defstruct @enforce_keys ++
              [
                :name,
                :id,
                state: :created,
                __counter__: 0,
                __loop_counter__: 0,
                __graphviz__: [size: "\"4,4\""],
                __args__: %{},
                __tasks__: %{},
                __opts__: [],
                __histories__: [],
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started, after events and transitions `init`, see `Flexflow.Api.init/1`"
  @callback init(t()) :: result()

  @callback handle_call(t(), term(), GenServer.from()) :: handle_call_return()
  @callback handle_cast(t(), term()) :: handle_cast_return()
  @callback handle_info(t(), term()) :: handle_info_return()
  @callback handle_continue(t(), term()) :: handle_continue_return()
  @callback terminate(t(), term()) :: term()

  @optional_callbacks [
    init: 1,
    handle_call: 3,
    handle_cast: 2,
    handle_info: 2,
    handle_continue: 2,
    terminate: 2
  ]

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Events.{Bypass, End, Start}
      alias Flexflow.Transitions.Pass

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__), only: [event: 1, event: 2, ~>: 2, transition: 2, transition: 3]

      for attribute <- [:__events__, :__transitions__, :__definitions__] do
        Module.register_attribute(__MODULE__, attribute, accumulate: true)
      end

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro event(key, opts \\ []) do
    quote bind_quoted: [key: key, opts: opts] do
      @__events__ {key, opts}
      @__definitions__ {:event, key}
    end
  end

  defmacro transition(key, tuple, opts \\ []) do
    quote bind_quoted: [key: key, tuple: tuple, opts: opts] do
      @__transitions__ {key, tuple, opts}
      @__definitions__ {:transition, Tuple.insert_at(tuple, 0, key)}
    end
  end

  def a ~> b, do: {a, b}

  def __after_compile__(env, _bytecode) do
    process = env.module.new()

    for {_, %{kind: :start, __out_edges__: []} = event} <- process.events do
      raise(ArgumentError, "Out edges of `#{inspect(Event.key(event))}` is empty")
    end

    for {_, %{kind: :end, __in_edges__: []} = event} <- process.events do
      raise(ArgumentError, "In edges of `#{inspect(Event.key(event))}` is empty")
    end

    for {_, %{__out_edges__: [], __in_edges__: []} = event} <- process.events do
      raise ArgumentError, "`#{inspect(Event.key(event))}` is isolated"
    end
  end

  defmacro __before_compile__(env) do
    events =
      env.module
      |> Module.get_attribute(:__events__)
      |> Enum.reverse()
      |> Enum.map(&Event.new/1)
      |> Event.validate()

    transitions =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.map(&Transition.new(&1, events))
      |> Transition.validate()

    definitions =
      env.module
      |> Module.get_attribute(:__definitions__)
      |> Enum.reverse()
      |> Enum.map(fn {k, v} -> {k, Util.normalize_module(v, events)} end)

    new_events =
      Map.new(events, fn o ->
        k = Event.key(o)
        in_edges = for(t <- transitions, t.to == k, do: {Transition.key(t), t.from})
        out_edges = for(t <- transitions, t.from == k, do: {Transition.key(t), t.to})

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    process = %__MODULE__{
      events: new_events,
      module: env.module,
      transitions: for(t <- transitions, into: %{}, do: {Transition.key(t), t}),
      __definitions__: definitions
    }

    quote bind_quoted: [module: __MODULE__, process: Macro.escape(process)] do
      alias Flexflow.Process

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{module}`

        #{inspect(process)}
        """
      end

      @__process__ %{process | __opts__: @__opts__}

      @spec new(Flexflow.id(), Flexflow.process_args()) :: Process.t()
      def new(id \\ Flexflow.Util.make_id(), args \\ %{}),
        do: struct!(@__process__, name: name(), id: id, __args__: args)

      for attribute <- [
            :__events__,
            :__opts__,
            :__transitions__,
            :__definitions__,
            :__module__,
            :__name__,
            :__process__
          ] do
        Module.delete_attribute(__MODULE__, attribute)
      end
    end
  end

  @behaviour Access
  @impl true
  def fetch(struct, key), do: Map.fetch(struct, key)
  @impl true
  def get_and_update(struct, key, fun) when is_function(fun, 1),
    do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  ###### Api ######

  @spec new(module(), Flexflow.id(), Flexflow.process_args()) :: result()
  def new(module, id, args \\ %{}), do: module.new(id, args)

  @spec init(t()) :: result()
  def init(%__MODULE__{module: module} = p) do
    with %__MODULE__{} = p <- Event.init(p), %__MODULE__{} = p <- Transition.init(p) do
      p = %{p | state: :active}

      if function_exported?(module, :init, 1) do
        module.init(p)
      else
        {:ok, p}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec handle_call(t(), term(), GenServer.from() | nil) :: handle_call_return()
  def handle_call(%__MODULE__{module: module} = p, input, from \\ nil) do
    if function_exported?(module, :handle_call, 3) do
      module.handle_call(p, input, from)
    else
      {:reply, :ok, p}
    end
  end

  @spec handle_cast(t(), term()) :: handle_cast_return()
  def handle_cast(%__MODULE__{module: module} = p, input) do
    if function_exported?(module, :handle_cast, 2) do
      module.handle_cast(p, input)
    else
      {:noreply, p}
    end
  end

  @spec handle_info(t(), term()) :: handle_info_return()
  def handle_info(%__MODULE__{} = p, {ref, result}) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {input, p} = pop_in(p.__tasks__[ref])
    IO.puts(inspect({:ok, input, result}))
    {:noreply, p}
  end

  def handle_info(%__MODULE__{} = p, {:DOWN, ref, :process, _monitor_pid, reason})
      when is_reference(ref) do
    {input, p} = pop_in(p.__tasks__[ref])
    IO.puts(inspect({:error, input, reason}))
    {:noreply, p}
  end

  def handle_info(%__MODULE__{module: module} = p, input) do
    if function_exported?(module, :handle_info, 2) do
      module.handle_info(p, input)
    else
      {:noreply, p}
    end
  end

  @spec handle_continue(t(), term()) :: handle_continue_return()
  def handle_continue(%__MODULE__{} = p, :init) do
    with {:ok, p} <- Telemetry.invoke_process(p, :process_init, &init/1),
         {:ok, p} <- Telemetry.invoke_process(p, :process_loop, &loop/1) do
      {:noreply, p}
    else
      {:error, reason} -> {:stop, reason, p}
    end
  end

  def handle_continue(%__MODULE__{module: module} = p, input) do
    if function_exported?(module, :handle_continue, 2) do
      module.handle_continue(p, input)
    else
      {:noreply, p}
    end
  end

  @spec terminate(t(), term()) :: term()
  def terminate(%__MODULE__{module: module} = p, reason) do
    if function_exported?(module, :terminate, 2) do
      module.terminate(p, reason)
    else
      :ok
    end
  end

  @spec async(t(), (() -> term()), term()) :: t()
  def async(%__MODULE__{} = p, f, value) when is_function(f, 0) do
    task = Task.Supervisor.async_nolink(TaskSupervisor, f)
    put_in(p.__tasks__[task.ref], value)
  end

  @max_loop_limit Config.get(:max_loop_limit)

  @spec loop(t()) :: result()
  def loop(%{state: ignore_state} = p) when ignore_state in [:waiting, :paused], do: {:ok, p}
  def loop(%{state: :active} = p), do: loop(%{p | state: :loop, __loop_counter__: 0})

  def loop(%{state: :loop, __loop_counter__: loop_counter, __counter__: counter} = p) do
    case next(%{p | __loop_counter__: loop_counter + 1, __counter__: counter + 1}) do
      {:error, reason} -> {:error, reason}
      {:ok, %{state: :loop} = p} -> loop(p)
      {:ok, p} -> {:ok, p}
    end
  end

  @spec next(t()) :: result()
  def next(%{__loop_counter__: loop_counter}) when loop_counter > @max_loop_limit,
    do: {:error, :deadlock_found}

  def next(%{events: events, transitions: transitions} = p) do
    ready_event_edges =
      for {_, %Event{state: :ready, __out_edges__: [_ | _] = out_edges} = event} <- events,
          {t, n} <- out_edges do
        {event, Map.fetch!(transitions, t), Map.fetch!(events, n)}
      end

    case ready_event_edges do
      [] -> {:ok, %{p | state: :waiting}}
      [_ | _] = a -> Enum.reduce(a, {:ok, p}, &Transition.dispatch/2)
    end
  end
end
