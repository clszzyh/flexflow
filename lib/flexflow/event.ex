defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Context
  alias Flexflow.Events.Blank
  alias Flexflow.Process
  alias Flexflow.State
  alias Flexflow.Util

  @states [:created, :initial]

  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type options :: Keyword.t()
  @type key :: Flexflow.state_type_or_module() | String.t()
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          state: state(),
          from: Flexflow.state_type(),
          to: Flexflow.state_type(),
          __opts__: options,
          __context__: Context.t()
        }

  @enforce_keys [:name, :module, :from, :to]
  defstruct @enforce_keys ++
              [
                state: :created,
                __opts__: [],
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok
  @callback graphviz_attribute :: keyword()
  @callback handle_enter(t(), Process.t()) :: {:ok, Process.t()} | {:error, term()}

  defmacro __using__(opts \\ []) do
    {inherit, opts} = Keyword.pop(opts, :inherit, Blank)

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
      def __inherit__, do: unquote(if __MODULE__ == inherit, do: nil, else: inherit)

      @impl true
      def name, do: @__name__

      if __MODULE__ != unquote(inherit) do
        unless Util.local_behaviour(unquote(inherit)) == unquote(__MODULE__) do
          raise ArgumentError, "Invalid inherit module: #{inspect(unquote(inherit))}"
        end

        defdelegate graphviz_attribute, to: unquote(inherit)
        defdelegate validate(a, p), to: unquote(inherit)
        defdelegate handle_enter(a, p), to: unquote(inherit)
      end

      defoverridable unquote(__MODULE__)
      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: {Flexflow.state_type(), Flexflow.state_type()}
  def key(%{from: from, to: to}), do: {from, to}

  @spec new({key(), {key(), key()}, options}, [State.t()], Process.process_tuple()) :: t()
  def new({_o, {from, _to}, _opts}, _states, _process_tuple) when is_binary(from),
    do: raise(ArgumentError, "Name `#{from}` should be an atom")

  def new({_o, {_from, to}, _opts}, _states, _process_tuple) when is_binary(to),
    do: raise(ArgumentError, "Name `#{to}` should be an atom")

  def new({o, {_from, _to}, _opts}, _states, _process_tuple) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, {from, to}, opts}, states, process_tuple) do
    from = Util.normalize_module(from, states)
    to = Util.normalize_module(to, states)
    new_1({o, {from, to}, opts}, states, process_tuple)
  end

  defp new_1({o, {from, to}, opts}, states, process_tuple) when is_atom(o) do
    new_1(
      {Util.normalize_module({o, from, to}, states), {from, to}, opts},
      states,
      process_tuple
    )
  end

  defp new_1(
         {{o, name}, {{_, from_name} = from, {_, to_name} = to}, opts},
         states,
         {_, process_name} = process_tuple
       ) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    states = Map.new(states, &{&1.name, &1})

    states[from_name] || states[String.to_atom("#{process_name}_s_#{from_name}")] ||
      raise(ArgumentError, "`#{inspect(from)}` is not defined")

    states[to_name] || states[String.to_atom("#{process_name}_s_#{to_name}")] ||
      raise(ArgumentError, "`#{inspect(to)}` is not defined")

    opts = opts ++ o.__opts__
    {ast, opts} = Keyword.pop(opts, :do)
    {module, name} = new_module(ast, o, name, process_tuple)

    %__MODULE__{
      module: module,
      name: name,
      from: from,
      to: to,
      __opts__: opts
    }
  end

  defp new_module(nil, parent_module, name, _), do: {parent_module, name}

  defp new_module(ast, parent_module, name, {process_module, process_name}) do
    module_name = Module.concat([process_module, parent_module, Macro.camelize(to_string(name))])
    name = String.to_atom("#{process_name}_e_#{name}")

    ast =
      quote generated: true do
        use unquote(__MODULE__), inherit: unquote(parent_module)
        unquote(ast)

        @impl true
        def name, do: unquote(name)
      end

    {:module, ^module_name, _byte_code, _} =
      Module.create(module_name, ast, Macro.Env.location(__ENV__))

    {module_name, name}
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
end

defmodule Flexflow.Events.Blank do
  @moduledoc false

  use Flexflow.Event

  @impl true
  def name, do: :blank

  @impl true
  def graphviz_attribute, do: []

  @impl true
  def validate(_, _), do: :ok

  @impl true
  def handle_enter(_, p), do: {:ok, p}
end
