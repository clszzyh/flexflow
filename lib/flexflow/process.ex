defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Event
  alias Flexflow.Transition
  alias Graph.Edge

  @type t :: %__MODULE__{
          module: module(),
          graph: Graph.t(),
          name: String.t()
        }

  @enforce_keys [:graph, :module]
  defstruct @enforce_keys ++ [:name]

  defmacro __using__(_opt) do
    quote do
      alias Flexflow.Events
      alias Flexflow.Transitions

      import unquote(__MODULE__),
        only: [defevent: 1, defevent: 2, deftransition: 2, deftransition: 3]

      Module.register_attribute(__MODULE__, :__events__, accumulate: true)
      Module.register_attribute(__MODULE__, :__transitions__, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro defevent(name, opts \\ [])

  defmacro defevent(module_or_name, opts) do
    quote bind_quoted: [module_or_name: module_or_name, opts: opts] do
      @__events__ {module_or_name, opts}
    end
  end

  defmacro deftransition(module_or_name, tuple, opts \\ [])

  defmacro deftransition(module_or_name, tuple, opts) do
    quote bind_quoted: [module_or_name: module_or_name, tuple: tuple, opts: opts] do
      @__transitions__ {module_or_name, tuple, opts}
    end
  end

  @spec new_graph([Event.t()], [Edge.t()]) :: Graph.t()
  def new_graph(vertices, edges) do
    Graph.new()
    |> Graph.add_vertices(vertices)
    |> Graph.add_edges(edges)
  end

  defmacro __before_compile__(env) do
    events =
      env.module
      |> Module.get_attribute(:__events__)
      |> Enum.reverse()
      |> Enum.map(&Event.define/1)
      |> Event.validate()

    event_map = for e <- events, into: %{}, do: {{e.module, e.id}, e}

    transitions =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.map(&Transition.define(&1, event_map))
      |> Transition.validate()

    graph = new_graph(events, transitions)

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

      Module.delete_attribute(__MODULE__, :__events__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__self__)
    end
  end
end
