defmodule Flexflow.Event do
  @moduledoc """
  Event
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

  @callback parent_module :: module()

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok

  @optional_callbacks [validate: 2, parent_module: 0]

  def impls do
    {:consolidated, modules} = Flexflow.EventTracker.__protocol__(:impls)
    modules
  end

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      defimpl Flexflow.EventTracker do
        def ping(_), do: :pong
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

  @spec new({key(), {key(), key()}, options}, [Activity.t()], module()) :: t()
  def new({_o, {from, _to}, _opts}, _activities, _process_module) when is_binary(from),
    do: raise(ArgumentError, "Name `#{from}` should be an atom")

  def new({_o, {_from, to}, _opts}, _activities, _process_module) when is_binary(to),
    do: raise(ArgumentError, "Name `#{to}` should be an atom")

  def new({o, {_from, _to}, _opts}, _activities, _process_module) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, {from, to}, opts}, activities, process_module) do
    from = Util.normalize_module(from, activities)
    to = Util.normalize_module(to, activities)
    new_1({o, {from, to}, opts}, activities, process_module)
  end

  defp new_1({o, {from, to}, opts}, activities, process_module) when is_atom(o) do
    new_1(
      {Util.normalize_module({o, from, to}, activities), {from, to}, opts},
      activities,
      process_module
    )
  end

  defp new_1({{o, name}, {from, to}, opts}, activities, process_module) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    activities = Map.new(activities, &{{&1.module, &1.name}, &1})

    activities[from] || raise(ArgumentError, "`#{inspect(from)}` is not defined")
    activities[to] || raise(ArgumentError, "`#{inspect(to)}` is not defined")

    opts = opts ++ o.__opts__
    {graphviz_attributes, opts} = Keyword.pop(opts, :graphviz_attributes, [])
    {ast, opts} = Keyword.pop(opts, :do)
    module = new_module(ast, o, name, process_module)

    %__MODULE__{
      module: module,
      name: name,
      from: from,
      to: to,
      __graphviz__: graphviz_attributes,
      __opts__: opts
    }
  end

  defp new_module(nil, parent_module, _, _), do: parent_module

  defp new_module(ast, parent_module, name, process_module) do
    module_name = Module.concat([process_module, parent_module, Macro.camelize(to_string(name))])

    ast =
      quote do
        use Flexflow.Event
        @impl true
        def name, do: unquote(name)

        @impl true
        def parent_module, do: unquote(parent_module)

        unquote(ast)
      end

    {:module, ^module_name, _byte_code, _} =
      Module.create(module_name, ast, Macro.Env.location(__ENV__))

    module_name
  end

  @spec validate([t()]) :: [t()]
  def validate(events) do
    if Enum.empty?(events), do: raise(ArgumentError, "Event is empty")

    for %__MODULE__{module: module, name: name} <- events, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Event `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    for %__MODULE__{from: from, to: to} <- events, reduce: [] do
      ary ->
        o = {from, to}
        if o in ary, do: raise(ArgumentError, "Event `#{inspect(o)}` is defined twice")
        ary ++ [o]
    end

    events
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
  def init(%Process{events: events} = p) do
    Enum.reduce(events, p, fn {key, event}, p ->
      put_in(p, [:events, key], %{event | state: :initial})
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
