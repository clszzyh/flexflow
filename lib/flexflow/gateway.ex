defmodule Flexflow.Gateway do
  @moduledoc """
  Gateway
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial]

  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type options :: Keyword.t()
  @type key :: Flexflow.identity_or_module() | String.t()
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          state: state(),
          from: Flexflow.identity(),
          to: Flexflow.identity(),
          __opts__: options,
          __graphviz__: Keyword.t(),
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

      defoverridable unquote(__MODULE__)

      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: Flexflow.identity()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({key(), {key(), key()}, options}, [Event.t()]) :: t()
  def new({_o, {from, _to}, _opts}, _events) when is_binary(from),
    do: raise(ArgumentError, "Name `#{from}` should be an atom")

  def new({_o, {_from, to}, _opts}, _events) when is_binary(to),
    do: raise(ArgumentError, "Name `#{to}` should be an atom")

  def new({o, {_from, _to}, _opts}, _events) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, {from, to}, opts}, events) do
    from = Util.normalize_module(from, events)
    to = Util.normalize_module(to, events)
    new_1({o, {from, to}, opts}, events)
  end

  defp new_1({o, {from, to}, opts}, events) when is_atom(o) do
    new_1({Util.normalize_module({o, from, to}, events), {from, to}, opts}, events)
  end

  defp new_1({{o, name}, {from, to}, opts}, events) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    events = Map.new(events, &{{&1.module, &1.name}, &1})

    events[from] || raise(ArgumentError, "`#{inspect(from)}` is not defined")
    events[to] || raise(ArgumentError, "`#{inspect(to)}` is not defined")

    opts = opts ++ o.__opts__
    {attributes, opts} = Keyword.pop(opts, :attributes, [])

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
  def validate(gateways) do
    if Enum.empty?(gateways), do: raise(ArgumentError, "Gateway is empty")

    for %__MODULE__{module: module, name: name} <- gateways, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Gateway `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    for %__MODULE__{from: from, to: to} <- gateways, reduce: [] do
      ary ->
        o = {from, to}
        if o in ary, do: raise(ArgumentError, "Gateway `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    gateways
  end

  @spec init(Process.t()) :: Process.t()
  def init(%Process{gateways: gateways} = p) do
    Enum.reduce(gateways, p, fn {key, gateway}, p ->
      put_in(p, [:gateways, key], %{gateway | state: :initial})
    end)
  end

  @spec dispatch({Event.t(), t(), Event.t()}, Process.result()) :: Process.result()
  def dispatch(_, {:error, reason}), do: {:error, reason}

  def dispatch(
        {%Event{module: from_module, name: from_name}, %__MODULE__{}, %Event{}},
        {:ok, p}
      ) do
    {:ok, put_in(p.events[{from_module, from_name}].state, :completed)}
  end
end
