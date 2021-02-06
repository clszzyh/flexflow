defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.State
  alias Flexflow.Context
  alias Flexflow.Process
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

  @type event_type :: :gen_statem.event_type()
  @type event_handler_result :: :gen_statem.event_handler_result(Flexflow.state_type())
  @type state_enter_result :: :gen_statem.state_enter_result(Flexflow.state_type())

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok

  @callback handle_enter(t(), Process.t()) :: {:ok, Process.t()} | {:error, term()}

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

      @impl true
      def validate(_, _), do: :ok

      @impl true
      def handle_enter(_, p), do: {:ok, p}

      defoverridable unquote(__MODULE__)

      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: {Flexflow.state_type(), Flexflow.state_type()}
  def key(%{from: from, to: to}), do: {from, to}

  @spec new({key(), {key(), key()}, options}, [State.t()], module()) :: t()
  def new({_o, {from, _to}, _opts}, _states, _process_module) when is_binary(from),
    do: raise(ArgumentError, "Name `#{from}` should be an atom")

  def new({_o, {_from, to}, _opts}, _states, _process_module) when is_binary(to),
    do: raise(ArgumentError, "Name `#{to}` should be an atom")

  def new({o, {_from, _to}, _opts}, _states, _process_module) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, {from, to}, opts}, states, process_module) do
    from = Util.normalize_module(from, states)
    to = Util.normalize_module(to, states)
    new_1({o, {from, to}, opts}, states, process_module)
  end

  defp new_1({o, {from, to}, opts}, states, process_module) when is_atom(o) do
    new_1(
      {Util.normalize_module({o, from, to}, states), {from, to}, opts},
      states,
      process_module
    )
  end

  defp new_1({{o, name}, {from, to}, opts}, states, process_module) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "`#{inspect(o)}` should implement #{__MODULE__}"
    end

    states = Map.new(states, &{{&1.module, &1.name}, &1})

    states[from] || raise(ArgumentError, "`#{inspect(from)}` is not defined")
    states[to] || raise(ArgumentError, "`#{inspect(to)}` is not defined")

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
      quote generated: true do
        use Flexflow.Event

        unquote(ast)

        @impl true
        def name, do: unquote(name)

        @impl true
        def validate(e, p), do: unquote(parent_module).validate(e, p)
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

  @spec init(Process.t()) :: Process.t()
  def init(%Process{events: events} = p) do
    Enum.reduce(events, p, fn {key, event}, p ->
      put_in(p, [:events, key], %{event | state: :initial})
    end)
  end

  @spec handle_event(:enter, Flexflow.state_type(), Flexflow.state_type(), Process.t()) ::
          state_enter_result
  @spec handle_event(event_type(), term, Flexflow.state_type(), Process.t()) ::
          event_handler_result()
  def handle_event(:enter, {from_module, _} = from, {to_module, _} = to, process) do
    from_state = process.states[from]
    to_state = process.states[to]
    t = process.events[{from, to}]

    with {:ok, process} <- from_module.handle_leave(from_state, process),
         {:ok, process} <- t.module.handle_enter(t, process),
         {:ok, process} <- to_module.handle_enter(to_state, process) do
      {:keep_state, process, process.__actions__}
    else
      {:error, reason} -> {:stop, reason, process}
    end
  end

  def handle_event(_event_type, _content, _state, _process) do
    {:next_state, :ok, nil}
  end

  @spec dispatch({State.t(), t(), State.t()}, Process.result()) :: Process.result()
  def dispatch(_, {:error, reason}), do: {:error, reason}

  def dispatch(
        {%State{module: from_module, name: from_name}, %__MODULE__{}, %State{}},
        {:ok, p}
      ) do
    {:ok, put_in(p.states[{from_module, from_name}].state, :completed)}
  end
end
