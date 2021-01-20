defmodule Flexflow.Node do
  @moduledoc """
  Node
  """

  alias Flexflow.Context
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial, :ready, :completed]

  @typedoc """
  Node state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type kind :: :start | :end | :intermediate
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          kind: kind(),
          __attributes__: keyword(),
          context: Context.t(),
          opts: Flexflow.node_opts()
        }

  @enforce_keys [:name, :module, :kind, :__attributes__]
  defstruct @enforce_keys ++
              [
                state: :created,
                opts: [],
                context: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started"
  @callback init(t(), Process.t()) :: {:ok, t()}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      @impl true
      def init(o, _), do: {:ok, o}

      defoverridable unquote(__MODULE__)

      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec attribute(kind()) :: keyword()
  def attribute(:intermediate), do: [shape: "box"]
  def attribute(:start), do: [color: "\".7 .3 1.0\""]
  def attribute(:end), do: [color: "red"]

  @spec new({Flexflow.key(), Flexflow.node_opts()}) :: t()
  def new({o, opts}) when is_atom(o), do: new({Util.normalize_module(o), opts})

  def new({{o, name}, opts}) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    {kind, opts} = Keyword.pop(opts, :kind, :intermediate)
    {attributes, opts} = Keyword.pop(opts, :attributes, attribute(kind))

    %__MODULE__{module: o, name: name, opts: opts, kind: kind, __attributes__: attributes}
  end

  def start?(%__MODULE__{kind: :start}), do: true
  def start?(%__MODULE__{}), do: false

  def end?(%__MODULE__{kind: :end}), do: true
  def end?(%__MODULE__{}), do: false

  @spec validate([t()]) :: [t()]
  def validate(nodes) do
    if Enum.empty?(nodes), do: raise(ArgumentError, "Node is empty")

    for %__MODULE__{module: module, name: name} <- nodes, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Node #{inspect(o)} is defined twice")
        ary ++ [o]
    end

    case Enum.filter(nodes, &start?/1) do
      [_] -> :ok
      [] -> raise(ArgumentError, "Need a start node")
      [_, _ | _] -> raise(ArgumentError, "Only need one start node")
    end

    Enum.find(nodes, &end?/1) || raise(ArgumentError, "Need one or more end node")

    nodes
  end
end
