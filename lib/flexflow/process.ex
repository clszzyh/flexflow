defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.Node
  alias Flexflow.Transition

  @states [:waiting, :initial, :active, :suspended, :terminated, :completed]

  @typedoc """
  Process state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          module: module(),
          graph: Graph.t(),
          name: Flexflow.name(),
          args: map(),
          opts: keyword(),
          nodes: Flexflow.nodes(),
          events: [Event.t()],
          context: Context.t(),
          transitions: Flexflow.transitions(),
          state: state()
        }

  @typedoc "Init result"
  @opaque result :: {:ok, t()} | {:error, term()}

  @enforce_keys [:graph, :module, :nodes, :transitions]
  defstruct @enforce_keys ++
              [
                :name,
                state: :waiting,
                args: %{},
                opts: [],
                events: [],
                context: Context.new()
              ]

  @spec start(module(), map()) :: result()
  def start(module, args \\ %{}) do
    process = module.new(args)
    process |> init()
  end

  @doc "Module name"
  @callback name :: Flexflow.name()
  @doc "Invoked when process is started, after nodes and transitions `init`, see `#{__MODULE__}.init/1`"
  @callback init(t() | {:error, term()}) :: result()

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Nodes
      alias Flexflow.Transitions

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__),
        only: [defnode: 1, defnode: 2, deftransition: 2, deftransition: 3]

      Module.register_attribute(__MODULE__, :__nodes__, accumulate: true)
      Module.register_attribute(__MODULE__, :__transitions__, accumulate: true)

      @before_compile unquote(__MODULE__)

      @impl true
      def init(o), do: {:ok, o}

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro defnode(name, opts \\ [])

  defmacro defnode(module_or_name, opts) do
    quote bind_quoted: [module_or_name: module_or_name, opts: opts] do
      @__nodes__ {module_or_name, opts}
    end
  end

  defmacro deftransition(module_or_name, tuple, opts \\ [])

  defmacro deftransition(module_or_name, tuple, opts) do
    quote bind_quoted: [module_or_name: module_or_name, tuple: tuple, opts: opts] do
      @__transitions__ {module_or_name, tuple, opts}
    end
  end

  @spec new(module(), Flexflow.nodes(), Transition.edge_map()) :: t()
  def new(module, nodes, edges) do
    graph =
      Graph.new()
      |> Graph.add_vertices(Map.keys(nodes))
      |> Graph.add_edges(Map.keys(edges))

    transitions = for {k, v} <- edges, into: %{}, do: {k.label, v}
    %__MODULE__{graph: graph, nodes: nodes, module: module, transitions: transitions}
  end

  defmacro __before_compile__(env) do
    nodes =
      env.module
      |> Module.get_attribute(:__nodes__)
      |> Enum.reverse()
      |> Enum.map(&Node.define/1)
      |> Node.validate()
      |> Map.new(&{{&1.module, &1.name}, &1})

    edges =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.into(%{}, &Transition.define(&1, nodes))
      |> Transition.validate()

    process = new(env.module, nodes, edges)

    quote bind_quoted: [module: __MODULE__, process: Macro.escape(process)] do
      alias Flexflow.Process

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{module}`

        #{inspect(process)}
        """
      end

      @__process__ %{process | opts: @__opts__}

      @spec new(map()) :: Process.t()
      def new(args \\ %{}), do: struct!(@__process__, name: name(), args: args)

      Module.delete_attribute(__MODULE__, :__nodes__)
      Module.delete_attribute(__MODULE__, :__opts__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__process__)
    end
  end

  @spec init(t()) :: result()
  def init(%__MODULE__{module: module, nodes: nodes, transitions: transitions} = p) do
    (Map.to_list(nodes) ++ Map.to_list(transitions))
    |> Enum.reduce_while(p, fn {key, %{module: module} = o}, p ->
      case module.init(o, p) do
        {:ok, %Node{} = node} ->
          {:cont, put_in(p, [:nodes, key], %{node | state: :initial})}

        {:ok, %Transition{} = transition} ->
          {:cont, put_in(p, [:transitions, key], %{transition | state: :initial})}

        {:error, reason} ->
          {:halt, {key, reason}}
      end
    end)
    |> module.init()
    |> case do
      {:error, reason} -> {:error, reason}
      {:ok, %__MODULE__{} = p} -> {:ok, %{p | state: :initial}}
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
