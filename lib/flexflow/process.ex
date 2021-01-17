defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.Node
  alias Flexflow.Transition

  @type state :: :active | :suspended | :terminated | :completed
  @type t :: %__MODULE__{
          module: module(),
          graph: Graph.t(),
          name: String.t() | nil,
          nodes: Flexflow.nodes(),
          events: [Event.t()],
          context: Context.t(),
          transitions: Flexflow.transitions(),
          state: state()
        }

  @enforce_keys [:graph, :module, :nodes, :transitions]
  defstruct @enforce_keys ++ [:name, state: :active, events: [], context: Context.new()]

  defmacro __using__(_opt) do
    quote do
      alias Flexflow.Nodes
      alias Flexflow.Transitions

      import unquote(__MODULE__),
        only: [defnode: 1, defnode: 2, deftransition: 2, deftransition: 3]

      Module.register_attribute(__MODULE__, :__nodes__, accumulate: true)
      Module.register_attribute(__MODULE__, :__transitions__, accumulate: true)

      @before_compile unquote(__MODULE__)
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
      |> Map.new(&{{&1.module, &1.id}, &1})

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

      @__process__ process

      @spec new(map()) :: Process.t()
      def new(args \\ %{}), do: struct!(@__process__, args)

      Module.delete_attribute(__MODULE__, :__nodes__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__process__)
    end
  end
end
