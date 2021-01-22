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
  @typedoc """
  * `async` - invoke using a separated task (except init callback), default `false`
  """
  @type option :: {:async, boolean()}
  @type options :: [option]
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          kind: kind(),
          __graphviz_attributes__: keyword(),
          __in_edges__: [{Flexflow.key_normalize(), Flexflow.key_normalize()}],
          __out_edges__: [{Flexflow.key_normalize(), Flexflow.key_normalize()}],
          __context__: Context.t(),
          __opts__: options
        }

  @enforce_keys [:name, :module, :kind]
  defstruct @enforce_keys ++
              [
                state: :created,
                __graphviz_attributes__: [],
                __in_edges__: [],
                __out_edges__: [],
                __opts__: [],
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started"
  @callback init(t(), Process.t()) :: {:ok, t()}

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      @__name__ Flexflow.Util.module_name(__MODULE__)
      def __opts__, do: unquote(opts)

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
  def attribute(:start), do: [shape: "doublecircle", color: "\".7 .3 1.0\""]
  def attribute(:end), do: [shape: "circle", color: "red"]

  @spec key(t()) :: Flexflow.key_normalize()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({Flexflow.key(), options}) :: t()
  def new({o, opts}) when is_atom(o), do: new({Util.normalize_module(o), opts})

  def new({{o, name}, opts}) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    opts = opts ++ o.__opts__
    {kind, opts} = Keyword.pop(opts, :kind, :intermediate)
    {attributes, opts} = Keyword.pop(opts, :attributes, attribute(kind))
    async = Keyword.get(opts, :async, false)

    attributes =
      if async, do: Keyword.merge([style: "bold", color: "red"], attributes), else: attributes

    %__MODULE__{
      module: o,
      name: name,
      kind: kind,
      __opts__: opts,
      __graphviz_attributes__: attributes
    }
  end

  @spec start?(t()) :: boolean()
  def start?(%__MODULE__{kind: :start}), do: true
  def start?(%__MODULE__{}), do: false

  @spec end?(t()) :: boolean()
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
