defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Config
  alias Flexflow.Context
  alias Flexflow.History
  alias Flexflow.Node
  alias Flexflow.ProcessManager
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
          nodes: Flexflow.nodes(),
          transitions: Flexflow.transitions(),
          state: state(),
          __args__: Flexflow.process_args(),
          __opts__: keyword(),
          __context__: Context.t(),
          __histories__: [History.t()],
          __identities__: [identity],
          __graphviz__: keyword(),
          __loop_counter__: integer(),
          __counter__: integer(),
          __tasks__: %{reference() => term()}
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type identity :: {:node | :transition, Flexflow.key_normalize()}
  @type handle_cast_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_info_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_continue_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_call_return ::
          {:reply, term, t()}
          | {:noreply, term}
          | {:stop, term, term}
          | {:stop, term, term, t()}
  @type server_return :: {:ok | :exist, pid} | {:error, term()}

  @enforce_keys [:module, :nodes, :transitions, :__identities__]
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

  @doc "Invoked when process is started, after nodes and transitions `init`, see `Flexflow.Api.init/1`"
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
      alias Flexflow.Nodes
      alias Flexflow.Nodes.{Bypass, End, Start}
      alias Flexflow.Transitions
      alias Flexflow.Transitions.Pass

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__),
        only: [
          intermediate_node: 1,
          intermediate_node: 2,
          ~>: 2,
          transition: 2,
          transition: 3
        ]

      Module.register_attribute(__MODULE__, :__nodes__, accumulate: true)
      Module.register_attribute(__MODULE__, :__transitions__, accumulate: true)
      Module.register_attribute(__MODULE__, :__identities__, accumulate: true)

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro intermediate_node(key, opts \\ []), do: define_node(key, opts)
  defmacro transition(key, tuple, opts \\ []), do: define_transition(key, tuple, opts)
  def a ~> b, do: {a, b}

  defp define_node(key, opts) do
    quote bind_quoted: [key: key, opts: opts] do
      @__nodes__ {key, opts}
      @__identities__ {:node, key}
    end
  end

  defp define_transition(key, tuple, opts) do
    quote bind_quoted: [key: key, tuple: tuple, opts: opts] do
      @__transitions__ {key, tuple, opts}
      @__identities__ {:transition, Tuple.insert_at(tuple, 0, key)}
    end
  end

  def __after_compile__(env, _bytecode) do
    process = env.module.new()

    for {_, node} <- process.nodes do
      case node.kind do
        :start ->
          if Enum.empty?(node.__out_edges__),
            do: raise(ArgumentError, "Out edges of #{inspect(Node.key(node))} is empty")

        :end ->
          if Enum.empty?(node.__in_edges__),
            do: raise(ArgumentError, "In edges of #{inspect(Node.key(node))} is empty")

        :intermediate ->
          :ok
      end
    end

    for {_, %{__out_edges__: [], __in_edges__: []} = node} <- process.nodes do
      raise ArgumentError, "#{inspect(Node.key(node))} is isolated"
    end
  end

  defmacro __before_compile__(env) do
    nodes =
      env.module
      |> Module.get_attribute(:__nodes__)
      |> Enum.reverse()
      |> Enum.map(&Node.new/1)
      |> Node.validate()

    transitions =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.map(&Transition.new(&1, nodes))
      |> Transition.validate()

    identities =
      env.module
      |> Module.get_attribute(:__identities__)
      |> Enum.reverse()
      |> Enum.map(fn {k, v} -> {k, Util.normalize_module(v)} end)

    new_nodes =
      Map.new(nodes, fn o ->
        k = Node.key(o)
        in_edges = for(t <- transitions, t.to == k, do: {Transition.key(t), t.from})
        out_edges = for(t <- transitions, t.from == k, do: {Transition.key(t), t.to})

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    process = %__MODULE__{
      nodes: new_nodes,
      module: env.module,
      transitions: for(t <- transitions, into: %{}, do: {Transition.key(t), t}),
      __identities__: identities
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

      @spec start(Flexflow.id(), Flexflow.process_args()) :: Process.server_return()
      def start(id, args \\ %{}), do: Process.start(__MODULE__, id, args)

      Module.delete_attribute(__MODULE__, :__nodes__)
      Module.delete_attribute(__MODULE__, :__opts__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__identities__)
      Module.delete_attribute(__MODULE__, :__module__)
      Module.delete_attribute(__MODULE__, :__name__)
      Module.delete_attribute(__MODULE__, :__process__)
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
  def new(module, id, args \\ %{}) do
    id
    |> module.new(args)
    |> telemetry_invoke(:process_init, &init/1)
  end

  @spec start(module(), Flexflow.id(), Flexflow.process_args()) :: server_return()
  def start(module, id, args \\ %{}), do: ProcessManager.server({module, id}, args)

  @spec init(t()) :: result()
  def init(%__MODULE__{module: module, nodes: nodes, transitions: transitions} = p) do
    (Map.to_list(nodes) ++ Map.to_list(transitions))
    |> Enum.reduce_while(p, fn {key, %{module: module} = o}, p ->
      case module.init(o, p) do
        {:ok, %Node{kind: :start} = node} ->
          {:cont, put_in(p, [:nodes, key], %{node | state: :ready})}

        {:ok, %Node{} = node} ->
          {:cont, put_in(p, [:nodes, key], %{node | state: :initial})}

        {:ok, %Transition{} = transition} ->
          {:cont, put_in(p, [:transitions, key], %{transition | state: :initial})}

        {:error, reason} ->
          {:halt, {key, reason}}
      end
    end)
    |> case do
      {:error, reason} ->
        {:error, reason}

      %__MODULE__{} = p ->
        p = %{p | state: :active}

        if function_exported?(module, :init, 1) do
          module.init(p)
        else
          {:ok, p}
        end
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
    {input, p} = pop_in(p.tasks[ref])
    IO.puts(inspect({:ok, input, result}))
    {:noreply, p}
  end

  def handle_info(%__MODULE__{} = p, {:DOWN, ref, :process, _monitor_pid, reason})
      when is_reference(ref) do
    {input, p} = pop_in(p.tasks[ref])
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
  def handle_continue(%__MODULE__{} = p, :loop) do
    case telemetry_invoke(p, :process_loop, &loop/1) do
      {:ok, p} -> {:noreply, p}
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

  @spec async(t(), (... -> term()), [term()]) :: t()
  def async(%__MODULE__{} = p, f, args) when is_function(f) and is_list(args) do
    task = Task.Supervisor.async_nolink(TaskSupervisor, fn -> apply(f, args) end)
    put_in(p.__tasks__[task.ref], args)
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

  def next(%{nodes: nodes, transitions: transitions} = p) do
    ready_node_edges =
      for {_, %Node{state: :ready, __out_edges__: [_ | _] = out_edges} = node} <- nodes,
          {t, n} <- out_edges do
        {node, Map.fetch!(transitions, t), Map.fetch!(nodes, n)}
      end

    case ready_node_edges do
      [] -> {:ok, %{p | state: :waiting}}
      [_ | _] = a -> Enum.reduce(a, {:ok, p}, &Transition.dispatch/2)
    end
  end

  @spec telemetry_invoke(t(), atom(), (t() -> result())) :: result()
  defp telemetry_invoke(p, name, f) do
    Telemetry.span(
      name,
      fn ->
        {state, result} = f.(p)
        {{state, result}, %{state: state}}
      end,
      %{id: p.id}
    )
  end
end
