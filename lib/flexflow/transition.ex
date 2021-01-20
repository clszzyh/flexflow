defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Context
  alias Flexflow.Node
  alias Flexflow.Process
  alias Flexflow.Util
  alias Graph.Edge

  @states [:created, :initial]

  @typedoc """
  Transition state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          opts: Flexflow.node_opts(),
          state: state(),
          __graphviz_attributes__: keyword(),
          context: Context.t(),
          from: Flexflow.key_normalize(),
          to: Flexflow.key_normalize()
        }

  @type edge :: Edge.t()
  @type edge_tuple :: {edge, t()}

  @enforce_keys [:name, :module, :from, :to]
  defstruct @enforce_keys ++
              [opts: [], __graphviz_attributes__: [], state: :created, context: Context.new()]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started"
  @callback init(t(), Process.t()) :: {:ok, t()}

  @doc "Invoked when process is enter this transition"
  @callback handle_enter(t(), Node.t(), Process.t()) :: :pass | :stop

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

  @spec new({Flexflow.key(), {Flexflow.key(), Flexflow.key()}, Flexflow.node_opts()}, [Node.t()]) ::
          edge_tuple
  def new({o, {from, to}, opts}, nodes) when is_atom(o) do
    new({Util.normalize_module({o, from, to}), {from, to}, opts}, nodes)
  end

  def new({{o, name}, {from, to}, opts}, nodes) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

    nodes = Map.new(nodes, &{{&1.module, &1.name}, &1})

    nodes[from] || raise(ArgumentError, "#{inspect(from)} is not defined")
    nodes[to] || raise(ArgumentError, "#{inspect(to)} is not defined")

    {attributes, opts} = Keyword.pop(opts, :attributes, [])
    attributes = attributes ++ if from == to, do: [color: "blue"], else: []

    transition = %__MODULE__{
      module: o,
      name: name,
      __graphviz_attributes__: attributes,
      opts: opts,
      from: from,
      to: to
    }

    {Edge.new(from, to, label: {o, name}), transition}
  end

  @spec enter(t(), Node.t(), Process.t()) :: {:ok, Process.t()} | {:error, atom()}
  def enter(%__MODULE__{module: module} = transition, node, process) do
    case module.handle_enter(transition, node, process) do
      :pass -> {:ok, process}
      :stop -> {:error, :stop}
      other -> raise ArgumentError, "Unmatched return value #{inspect(other)}"
    end
  end

  @spec validate([edge_tuple()]) :: [edge_tuple()]
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    for {_, %__MODULE__{module: module, name: name}} <- transitions, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice")
        ary ++ [o]
    end

    for {%Edge{v1: v1, v2: v2}, _} <- transitions, reduce: [] do
      ary ->
        o = {v1, v2}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice")
        ary ++ [o]
    end

    transitions
  end
end
