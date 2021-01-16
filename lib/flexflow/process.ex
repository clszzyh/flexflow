defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  @type t :: %__MODULE__{
          graph: Graph.t(),
          name: String.t()
        }

  alias Flexflow.Event
  alias Flexflow.Transition

  @enforce_keys [:graph]
  defstruct @enforce_keys ++ [:name]

  defmacro __using__(_opt) do
    quote do
      import unquote(__MODULE__), only: [defevent: 1, defevent: 2, deftransition: 2]

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

  defmacro deftransition(module_or_name, tuple) do
    quote bind_quoted: [module_or_name: module_or_name, tuple: tuple] do
      @__transitions__ {module_or_name, tuple}
    end
  end

  defmacro __before_compile__(env) do
    events =
      env.module
      |> Module.get_attribute(:__events__)
      |> Enum.reverse()
      |> Enum.map(&Event.define/1)

    transitions =
      env.module
      |> Module.get_attribute(:__transitions__)
      |> Enum.reverse()
      |> Enum.map(&Transition.define/1)

    if Enum.empty?(events), do: raise(ArgumentError, "Event is empty!")
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    graph =
      Graph.new()
      |> Graph.add_vertices(events)
      |> Graph.add_edges(transitions)
      |> Macro.escape()

    quote do
      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`

        #{inspect(unquote(graph))}
        """
      end

      @__self__ struct!(unquote(__MODULE__), graph: unquote(graph))

      def __self__, do: @__self__

      def new(args \\ %{}) do
        struct!(@__self__, args)
      end

      Module.delete_attribute(__MODULE__, :__events__)
      Module.delete_attribute(__MODULE__, :__transitions__)
      Module.delete_attribute(__MODULE__, :__self__)
    end
  end
end
