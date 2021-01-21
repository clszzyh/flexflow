defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Context
  alias Flexflow.History
  alias Flexflow.Node
  alias Flexflow.Transition
  alias Flexflow.Util

  @states [:created, :active, :loop]

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
          start_node: Flexflow.key_normalize(),
          state: state(),
          __args__: Flexflow.process_args(),
          __opts__: keyword(),
          __context__: Context.t(),
          __histories__: [History.t()],
          __identities__: [identity],
          __graphviz_attributes__: keyword(),
          __loop_counter__: integer(),
          __counter__: integer()
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type identity :: {:node | :transition, Flexflow.key_normalize()}
  @type handle_cast_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_info_return :: {:noreply, t()} | {:stop, term(), t()}
  @type handle_call_return ::
          {:reply, term, t()}
          | {:noreply, term}
          | {:stop, term, term}
          | {:stop, term, term, t()}

  @enforce_keys [:module, :nodes, :start_node, :transitions, :__identities__]
  defstruct @enforce_keys ++
              [
                :name,
                :id,
                state: :created,
                __counter__: 0,
                __loop_counter__: 0,
                __graphviz_attributes__: [size: "\"4,4\""],
                __args__: %{},
                __opts__: [],
                __histories__: [],
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started, after nodes and transitions `init`, see `Flexflow.Api.init/1`"
  @callback init(t() | {:error, term()}) :: result()

  @callback handle_call(t(), term(), GenServer.from()) :: handle_call_return()
  @callback handle_cast(t(), term()) :: handle_cast_return()
  @callback handle_info(t(), term()) :: handle_info_return()
  @callback terminate(t(), term()) :: term()

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Api
      alias Flexflow.Nodes
      alias Flexflow.Transitions

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__),
        only: [
          intermediate_node: 1,
          intermediate_node: 2,
          start_node: 1,
          start_node: 2,
          end_node: 1,
          end_node: 2,
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

      @impl true
      def init(o), do: {:ok, o}

      @impl true
      def handle_call(process, term, from), do: Api.call(process, term, from)

      @impl true
      def handle_cast(process, term), do: Api.cast(process, term)

      @impl true
      def handle_info(process, term), do: Api.info(process, term)

      @impl true
      def terminate(process, term), do: Api.terminate(process, term)

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro intermediate_node(key, opts \\ []), do: define_node(key, opts)
  defmacro start_node(key, opts \\ []), do: define_node(key, [kind: :start] ++ opts)
  defmacro end_node(key, opts \\ []), do: define_node(key, [kind: :end] ++ opts)
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

  @spec new(module(), [Node.t()], [Transition.t()], [identity]) :: t()
  def new(module, nodes, transitions, identities) do
    new_nodes =
      Map.new(nodes, fn o ->
        k = Node.key(o)
        in_edges = for(t <- transitions, t.to == k, do: {Transition.key(t), t.from})
        out_edges = for(t <- transitions, t.from == k, do: {Transition.key(t), t.to})

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    %__MODULE__{
      nodes: new_nodes,
      module: module,
      start_node: nodes |> Enum.find(&Node.start?/1) |> Node.key(),
      transitions: for(t <- transitions, into: %{}, do: {Transition.key(t), t}),
      __identities__: identities
    }
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

    edges =
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

    process = new(env.module, nodes, edges, identities)

    quote bind_quoted: [module: __MODULE__, process: Macro.escape(process)] do
      alias Flexflow.Api
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

      @spec start(Flexflow.id(), Flexflow.process_args()) :: Process.result()
      def start(id, args \\ %{}), do: Api.start(__MODULE__, id, args)

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
end
