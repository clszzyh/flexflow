defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Context
  alias Flexflow.Events.Blank
  alias Flexflow.Process
  alias Flexflow.State
  alias Flexflow.Util

  @type options :: Keyword.t()
  @type key :: Flexflow.state_type_or_module() | String.t()
  @type t :: %__MODULE__{
          module: module(),
          parent_module: module(),
          name: Flexflow.name(),
          from: Flexflow.state_key(),
          to: Flexflow.state_key(),
          __opts__: options,
          __op__: Flexflow.name(),
          results: MapSet.t(atom()),
          context: Context.t()
        }

  @enforce_keys [:name, :module, :from, :to, :results, :parent_module, :__op__]
  defstruct @enforce_keys ++ [__opts__: [], context: Context.new()]

  @type event_result :: {:ok, atom()} | {:error, term()}

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked after compile, return :ok if valid"
  @callback init(t(), Process.t()) :: Process.result()
  @callback validate(t(), Process.t()) :: :ok
  @callback graphviz_attribute :: keyword()
  @callback handle_input(term(), State.t(), Process.t()) :: event_result
  @callback is_event(term()) :: boolean()
  @callback handle_result(event_result, Process.event_type(), term(), State.t(), Process.t()) ::
              Process.event_result()

  defmacro __using__(opts \\ []) do
    {inherit, opts} = Keyword.pop(opts, :inherit, Blank)

    quote do
      @behaviour unquote(__MODULE__)
      alias Flexflow.{Event, Process, State}

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      defimpl(Flexflow.EventTracker, do: def(ping(_), do: :pong))

      @__name__ Flexflow.Util.module_name(__MODULE__)
      def __opts__, do: unquote(opts)
      def __inherit__, do: unquote(if __MODULE__ == inherit, do: nil, else: inherit)

      @impl true
      def name, do: @__name__

      if __MODULE__ != unquote(inherit) do
        unless Util.local_behaviour(unquote(inherit)) == unquote(__MODULE__) do
          raise ArgumentError, "Invalid inherit module: #{inspect(unquote(inherit))}"
        end

        defdelegate graphviz_attribute, to: Blank
        defdelegate is_event(t), to: Blank

        defdelegate init(a, p), to: unquote(inherit)
        defdelegate validate(a, p), to: unquote(inherit)
        defdelegate handle_input(term, s, p), to: unquote(inherit)
        defdelegate handle_result(result, t, term, s, p), to: unquote(inherit)
      end

      defoverridable unquote(__MODULE__)
      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: {Flexflow.state_key(), Flexflow.state_key()}
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

    from_state = states[from_name] || states[String.to_atom("#{process_name}_s_#{from_name}")]
    from_state || raise(ArgumentError, "`#{inspect(from)}` is not defined")

    to_state = states[to_name] || states[String.to_atom("#{process_name}_s_#{to_name}")]
    to_state || raise(ArgumentError, "`#{inspect(to)}` is not defined")

    opts = opts ++ o.__opts__
    {results, opts} = Keyword.pop(opts, :results, [:ignore])
    {ast, opts} = Keyword.pop(opts, :do)
    {new_module, name} = new_module(ast, o, name, process_tuple)

    %__MODULE__{
      module: new_module,
      name: name,
      from: from_state.name,
      to: to_state.name,
      __opts__: opts,
      results: MapSet.new(results),
      parent_module: o,
      __op__: o.name
    }
  end

  defp new_module(nil, parent_module, name, _), do: {parent_module, name}

  defp new_module(ast, parent_module, name, {process_module, process_name}) do
    module_name = Module.concat([process_module, parent_module, Macro.camelize(to_string(name))])
    name = String.to_atom("#{process_name}_e_#{name}")

    ast =
      quote generated: true do
        use unquote(__MODULE__), inherit: unquote(parent_module)
        alias unquote(parent_module)

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

    for %__MODULE__{module: module, name: name, from: from, to: to, results: results, __op__: op} <-
          events,
        reduce: {[], [], %{}} do
      {ary1, ary2, map} ->
        o1 = {module, name}
        if o1 in ary1, do: raise(ArgumentError, "Event `#{inspect(o1)}` is defined twice")

        o2 = {from, to}
        if o2 in ary2, do: raise(ArgumentError, "Event `#{inspect(o2)}` is defined twice")

        map =
          case map[{from, op}] do
            nil ->
              Map.put(map, {from, op}, results)

            mapset ->
              if MapSet.disjoint?(mapset, results) do
                Map.put(map, {from, op}, MapSet.union(mapset, results))
              else
                raise(ArgumentError, "Event #{name} has duplicate results: #{inspect(results)}")
              end
          end

        {[o1 | ary1], [o2 | ary2], map}
    end

    events
  end

  @spec init(Process.t()) :: Process.result()
  def init(%{events: events} = p) do
    Enum.reduce_while(events, p, fn {key, event}, p ->
      case event.module.init(event, p) do
        {:ok, event} -> {:cont, put_in(p, [:events, key], event)}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      %Process{} = p -> {:ok, p}
    end
  end
end

defmodule Flexflow.Events.Blank do
  @moduledoc false

  use Flexflow.Event

  @impl true
  def name, do: :blank

  @impl true
  def init(e, _), do: {:ok, e}

  @impl true
  def graphviz_attribute, do: []

  @impl true
  def validate(_, _), do: :ok

  @impl true
  def handle_input(_, _, _), do: {:ok, :ignore}

  @impl true
  def is_event(_), do: true

  @impl true
  def handle_result(_, _, _, _, p), do: {:ok, p}
end
