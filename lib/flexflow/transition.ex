defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial]

  @typedoc """
  Transition state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type options :: keyword()
  @type key :: Flexflow.key() | String.t()
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

  @spec key(t()) :: Flexflow.key_normalize()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({key(), {key(), key()}, options}, [Event.t()]) :: t()
  def new({o, {from, to}, opts}, events) when is_binary(from) do
    new({o, {Util.normalize_module(from, events), to}, opts}, events)
  end

  def new({o, {from, to}, opts}, events) when is_binary(to) do
    new({o, {from, Util.normalize_module(to, events)}, opts}, events)
  end

  def new({o, {from, to}, opts}, events) when is_atom(o) or is_binary(o) do
    new({Util.normalize_module({o, from, to}), {from, to}, opts}, events)
  end

  def new({{o, name}, {from, to}, opts}, events) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

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
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty")

    for %__MODULE__{module: module, name: name} <- transitions, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Transition `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    for %__MODULE__{from: from, to: to} <- transitions, reduce: [] do
      ary ->
        o = {from, to}
        if o in ary, do: raise(ArgumentError, "Transition `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    transitions
  end

  @spec init(Process.t()) :: Process.t() | {:error, term()}
  def init(%Process{transitions: transitions} = p) do
    Enum.reduce(transitions, p, fn {key, transition}, p ->
      put_in(p, [:transitions, key], %{transition | state: :initial})
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
