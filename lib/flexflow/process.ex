defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Node
  alias Flexflow.Transition
  alias Graph.Edge

  @type state :: :active | :suspended | :terminated | :completed
  @type t :: %__MODULE__{
          module: module(),
          graph: Graph.t(),
          name: String.t(),
          state: state()
        }

  @enforce_keys [:graph, :module]
  defstruct @enforce_keys ++ [:name, state: :active]

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

  @spec new_graph([Node.t()], [Edge.t()]) :: Graph.t()
  def new_graph(vertices, edges) do
    Graph.new()
    |> Graph.add_vertices(vertices)
    |> Graph.add_edges(edges)
  end

  defmacro __before_compile__(env) do
    nodes =
      env.module
      |> Module.get_attribute(:__nodes__)
      |> Enum.reverse()
      |> Enum.map(&Node.define/1)
      |> Node.validate()

    node_map = for e <- nodes, into: %{}, do: {{e.module, e.id}, e}

    transitions =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.map(&Transition.define(&1, node_map))
      |> Transition.validate()

    graph = new_graph(nodes, transitions)

    quote bind_quoted: [module: __MODULE__, graph: Macro.escape(graph)] do
      alias Flexflow.Process

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{module}`

        #{inspect(graph)}
        """
      end

      @__self__ struct!(module, graph: graph, module: __MODULE__)

      def __self__, do: @__self__
      @spec new(map()) :: Process.t()
      def new(args \\ %{}), do: struct!(@__self__, args)

      Module.delete_attribute(__MODULE__, :__nodes__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__self__)
    end
  end
end
