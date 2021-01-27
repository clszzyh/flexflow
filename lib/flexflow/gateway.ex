defmodule Flexflow.Gateway do
  @moduledoc """
  Gateway
  """

  alias Flexflow.Activity
  alias Flexflow.Context
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

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok

  @optional_callbacks [validate: 2]

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

  @spec new({key(), {key(), key()}, options}, [Activity.t()]) :: t()
  def new({_o, {from, _to}, _opts}, _activities) when is_binary(from),
    do: raise(ArgumentError, "Name `#{from}` should be an atom")

  def new({_o, {_from, to}, _opts}, _activities) when is_binary(to),
    do: raise(ArgumentError, "Name `#{to}` should be an atom")

  def new({o, {_from, _to}, _opts}, _activities) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, {from, to}, opts}, activities) do
    from = Util.normalize_module(from, activities)
    to = Util.normalize_module(to, activities)
    new_1({o, {from, to}, opts}, activities)
  end

  defp new_1({o, {from, to}, opts}, activities) when is_atom(o) do
    new_1({Util.normalize_module({o, from, to}, activities), {from, to}, opts}, activities)
  end

  defp new_1({{o, name}, {from, to}, opts}, activities) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    activities = Map.new(activities, &{{&1.module, &1.name}, &1})

    activities[from] || raise(ArgumentError, "`#{inspect(from)}` is not defined")
    activities[to] || raise(ArgumentError, "`#{inspect(to)}` is not defined")

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

  @spec validate_process(t(), Process.t()) :: :ok
  def validate_process(%__MODULE__{module: module} = g, %Process{} = p) do
    if function_exported?(module, :validate, 2) do
      :ok = module.validate(g, p)
    else
      :ok
    end
  end

  @spec init(Process.t()) :: Process.t()
  def init(%Process{gateways: gateways} = p) do
    Enum.reduce(gateways, p, fn {key, gateway}, p ->
      put_in(p, [:gateways, key], %{gateway | state: :initial})
    end)
  end

  @spec dispatch({Activity.t(), t(), Activity.t()}, Process.result()) :: Process.result()
  def dispatch(_, {:error, reason}), do: {:error, reason}

  def dispatch(
        {%Activity{module: from_module, name: from_name}, %__MODULE__{}, %Activity{}},
        {:ok, p}
      ) do
    {:ok, put_in(p.activities[{from_module, from_name}].state, :completed)}
  end
end
