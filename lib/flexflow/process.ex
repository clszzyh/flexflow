defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.EventDispatcher
  alias Flexflow.State
  alias Flexflow.Util

  @type action :: :gen_statem.action()
  @type event_type :: :gen_statem.event_type()

  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          id: Flexflow.id() | nil,
          state: Flexflow.state_key(),
          states: %{Flexflow.state_key() => State.t()},
          events: %{Flexflow.state_key() => Event.t()},
          parent: Flexflow.process_key(),
          childs: [Flexflow.process_key()],
          request_id: String.t(),
          __args__: Flexflow.process_args(),
          __vsn__: [{module(), term()}],
          __opts__: Keyword.t(),
          context: Context.t(),
          __definitions__: [definition],
          __actions__: [action],
          __listeners__: %{EventDispatcher.listener() => EventDispatcher.listen_result()},
          __loop__: integer(),
          __counter__: integer(),
          __tasks__: %{reference() => term()}
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type state_result :: :ignore | result | {:ok, State.t()}
  @type definition ::
          {:states, Flexflow.state_key()}
          | {:events, {Flexflow.state_key(), Flexflow.state_key()}}
  @type process_tuple :: {module(), Flexflow.name()}

  @enforce_keys [:module, :states, :events, :state, :__definitions__]
  # @derive {Inspect, except: [:__definitions__]}
  defstruct @enforce_keys ++
              [
                :name,
                :id,
                :__vsn__,
                :parent,
                :request_id,
                childs: [],
                __counter__: 0,
                __loop__: 0,
                __args__: %{},
                __tasks__: %{},
                __opts__: [],
                __actions__: [],
                __listeners__: %{},
                context: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @callback init(t()) :: result()

  @callback handle_result(term(), t()) :: result()

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Events.Pass
      alias Flexflow.States.{Bypass, End, Start}

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      defimpl(Flexflow.ProcessTracker, do: def(ping(_), do: :pong))

      import unquote(__MODULE__),
        only: [state: 1, state: 2, state: 3, ~>: 2, event: 2, event: 3, event: 4]

      for attribute <- [:__states__, :__events__, :__definitions__] do
        Module.register_attribute(__MODULE__, attribute, accumulate: true)
      end

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      @impl true
      def init(p), do: {:ok, p}

      @impl true
      def handle_result(_, p), do: {:ok, p}
      defoverridable unquote(__MODULE__)
    end
  end

  def a ~> b, do: {a, b}
  defmacro state(key), do: defstate(key, [])
  defmacro state(key, opts), do: defstate(key, opts)
  defmacro state(key, opts, block), do: defstate(key, opts ++ block)
  defmacro event(key, tuple), do: defevent(key, tuple, [])
  defmacro event(key, tuple, opts), do: defevent(key, tuple, opts)
  defmacro event(key, tuple, opts, block), do: defevent(key, tuple, opts ++ block)

  defp defstate(key, opts) do
    quote bind_quoted: [key: key, opts: Macro.escape(opts)] do
      @__states__ {key, opts}
      @__definitions__ {:states, key}
    end
  end

  defp defevent(key, tuple, opts) do
    quote bind_quoted: [key: key, tuple: tuple, opts: Macro.escape(opts)] do
      @__events__ {key, tuple, opts}
      @__definitions__ {:events, Tuple.insert_at(tuple, 0, key)}
    end
  end

  def __after_compile__(env, _bytecode) do
    {:ok, process} = env.module.new()

    for map <- [process.states, process.events], {_, %{module: module} = state} <- map do
      :ok = module.validate(state, process)
    end
  end

  defp new_process(env) do
    process_name = Module.get_attribute(env.module, :__name__)

    states =
      env.module
      |> Module.get_attribute(:__states__)
      |> Enum.reverse()
      |> Enum.map(&State.new(&1, {env.module, process_name}))
      |> State.validate()

    events =
      env.module
      |> Module.get_attribute(:__events__)
      |> Enum.reverse()
      |> Enum.map(&Event.new(&1, states, {env.module, process_name}))
      |> Event.validate()

    definitions =
      env.module
      |> Module.get_attribute(:__definitions__)
      |> Enum.reverse()
      |> Enum.map(fn {k, v} ->
        v =
          case v do
            {_, from, to} ->
              {Util.normalize_module(from, states)
               |> State.normalize_state_key(states, process_name),
               Util.normalize_module(to, states)
               |> State.normalize_state_key(states, process_name)}

            v ->
              Util.normalize_module(v, states) |> State.normalize_state_key(states, process_name)
          end

        {k, v}
      end)

    new_states =
      Map.new(states, fn o ->
        k = State.key(o)
        in_edges = for(t <- events, t.to == k, do: t.from)
        out_edges = for(t <- events, t.from == k, do: t.to)

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    %__MODULE__{
      states: new_states,
      module: env.module,
      state: Enum.find_value(states, fn a -> if State.start?(a), do: State.key(a) end),
      events: for(t <- events, into: %{}, do: {Event.key(t), t}),
      __definitions__: definitions
    }
  end

  defmacro __before_compile__(env) do
    quote bind_quoted: [module: __MODULE__, process: Macro.escape(new_process(env))] do
      alias Flexflow.Process

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{module}`

        #{inspect(process)}
        """
      end

      @__process__ %{process | __opts__: @__opts__}
      @__vsn__ (for {key, name} <- @__process__.__definitions__, uniq: true do
                  module = @__process__[key][name].module
                  {key, {name, module}, module.module_info(:attributes)[:vsn]}
                end) ++ [{:app, :flexflow, Mix.Project.config()[:version]}]
      @states for {_, %{module: module}} <- @__process__.states,
                  into: %{},
                  do: {module.name, module}
      @events for {_, %{module: module}} <- @__process__.events,
                  into: %{},
                  do: {module.name, module}

      def __vsn__ do
        [{:process, {name(), __MODULE__}, __MODULE__.module_info(:attributes)[:vsn]} | @__vsn__]
      end

      def __events__, do: @events
      def __states__, do: @states

      transitions = for {:events, {from, to}} <- @__process__.__definitions__, do: {from, to}
      defguard is_transition(from, to) when {from, to} in unquote(transitions)

      @spec new(Flexflow.id(), Flexflow.process_args()) :: {:ok, Process.t()}
      def new(id \\ Flexflow.Util.make_id(), args \\ %{}) do
        body =
          Map.merge(
            %{
              name: name(),
              id: id,
              request_id: Util.random(),
              __vsn__: :crypto.hash(:md5, :erlang.term_to_binary(__vsn__())),
              __args__: Map.drop(args, [:parent, :request_id])
            },
            Map.take(args, [:parent, :request_id])
          )

        {:ok, struct!(@__process__, body)}
      end

      for attribute <- [
            :events,
            :states,
            :__states__,
            :__opts__,
            :__events__,
            :__definitions__,
            :__vsn__,
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
  def fetch(struct, k), do: Map.fetch(struct, k)
  @impl true
  def get_and_update(struct, k, f) when is_function(f, 1), do: Map.get_and_update(struct, k, f)
  @impl true
  def pop(struct, k), do: Map.pop(struct, k)

  ###### Api ######

  @spec new(module(), Flexflow.id(), Flexflow.process_args()) :: result()
  def new(module, id, args \\ %{}), do: module.new(id, args)

  @spec init(module(), Flexflow.id(), Flexflow.process_args()) :: result()
  def init(module, id, args \\ %{}) do
    with {:ok, %__MODULE__{} = p} <- module.new(id, args),
         {:ok, %__MODULE__{} = p} <- State.init(p),
         {:ok, %__MODULE__{} = p} <- Event.init(p),
         {:ok, %__MODULE__{} = p} <- module.init(p) do
      {:ok, p}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec handle_event(:enter, Flexflow.state_key(), t()) :: result
  @spec handle_event(event_type(), term, t()) :: result

  def handle_event(:enter, to, %{state: to} = process) do
    state = process.states[to]
    state.module.handle_enter(state, process)
  end

  def handle_event(:enter, from, %{state: to} = process) do
    from_state = process.states[from]
    to_state = process.states[to]

    with {:ok, process} <-
           from_state.module.handle_leave(from_state, process) |> parse_result(process),
         {:ok, process} <-
           to_state.module.handle_enter(to_state, process) |> parse_result(process) do
      {:ok, process}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # def handle_event(event_type, {:to, to}, %{state: from} = process) do
  #   case process.events[{from, to}] do
  #     nil -> {:error, "Undefined event #{inspect({from, to})}"}
  #     event -> event.module.handle_to(event_type, event, process) |> parse_result(process)
  #   end
  # end

  def handle_event(event_type, {:event, input}, %{state: key} = process) do
    state = process.states[key]
    state.module.handle_input(event_type, input, state, process) |> parse_result(process)
  end

  def handle_event(event_type, content, %{state: state} = process) do
    state = process.states[state]
    state.module.handle_event(event_type, content, state, process) |> parse_result(process)
  end

  def parse_result({:error, reason}, _process), do: {:error, reason}
  def parse_result(:ignore, process), do: {:ok, process}
  def parse_result({:ok, %__MODULE__{} = p}, _process), do: {:ok, p}

  def parse_result({:ok, %State{} = state}, %{state: key} = process) do
    {:ok, put_in(process, [:states, key], state)}
  end

  def parse_result(result, %{module: module} = process) do
    module.handle_result(result, process)
  end
end
