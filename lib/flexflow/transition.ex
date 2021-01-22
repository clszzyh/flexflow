defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Context
  alias Flexflow.Node
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial]

  @typedoc """
  Transition state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @typedoc """

    * `async` - `t:Flexflow.Node.option/0`
  """
  @type option :: {:async, boolean()}
  @type options :: [option]
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          state: state(),
          from: Flexflow.key_normalize(),
          to: Flexflow.key_normalize(),
          __opts__: options,
          __graphviz__: keyword(),
          __context__: Context.t()
        }

  @enforce_keys [:name, :module, :from, :to]
  defstruct @enforce_keys ++
              [
                state: :created,
                __opts__: [],
                __graphviz__: [],
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

  @spec key(t()) :: Flexflow.key_normalize()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({Flexflow.key(), {Flexflow.key(), Flexflow.key()}, options}, [Node.t()]) :: t()
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

    opts = opts ++ o.__opts__
    {attributes, opts} = Keyword.pop(opts, :attributes, [])
    attributes = attributes ++ if from == to, do: [color: "blue"], else: []
    async = Keyword.get(opts, :async, false)

    attributes =
      if async, do: Keyword.merge([style: "bold", color: "red"], attributes), else: attributes

    %__MODULE__{
      module: o,
      name: name,
      from: from,
      to: to,
      __graphviz__: attributes,
      __opts__: opts
    }
  end

  @spec validate([t()]) :: [t()]
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    for %__MODULE__{module: module, name: name} <- transitions, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice")
        ary ++ [o]
    end

    for %__MODULE__{from: from, to: to} <- transitions, reduce: [] do
      ary ->
        o = {from, to}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice")
        ary ++ [o]
    end

    transitions
  end

  @spec dispatch({Node.t(), t(), Node.t()}, Process.result()) :: Process.result()
  def dispatch(_, {:error, reason}), do: {:error, reason}

  def dispatch(
        {%Node{module: from_module, name: from_name}, %__MODULE__{}, %Node{}},
        {:ok, p}
      ) do
    {:ok, put_in(p.nodes[{from_module, from_name}].state, :completed)}
  end
end
