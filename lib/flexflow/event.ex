defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Context
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial, :ready, :completed, :pending, :error]
  @state_changes [created: [:initial], created: [:initial, :ready], initial: [:ready]]

  @typedoc """
  Event state

  #{inspect(@states)}
  """
  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type state_change :: [state()]
  @type kind :: :start | :end | :intermediate
  @type options :: keyword()
  @type edge :: {Flexflow.key_normalize(), Flexflow.key_normalize()}
  @type before_change_result :: :ok | {:ok, t()} | {:ok, term()} | {:error, term()}
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          kind: kind(),
          __async__: boolean(),
          __graphviz__: keyword(),
          __in_edges__: [edge()],
          __out_edges__: [edge()],
          __context__: Context.t(),
          __opts__: options
        }

  @enforce_keys [:name, :module, :kind]
  defstruct @enforce_keys ++
              [
                state: :created,
                __async__: false,
                __graphviz__: [],
                __in_edges__: [],
                __out_edges__: [],
                __opts__: [],
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked before event state changes"
  @callback before_change({state(), state_change()}, t(), Process.t()) :: before_change_result()

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
      def before_change(_, _, _), do: :ok

      defoverridable unquote(__MODULE__)

      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec attribute(kind()) :: keyword()
  defp attribute(:intermediate), do: [shape: "box"]
  defp attribute(:start), do: [shape: "doublecircle", color: "\".7 .3 1.0\""]
  defp attribute(:end), do: [shape: "circle", color: "red"]

  @spec key(t()) :: Flexflow.key_normalize()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({Flexflow.key(), options}) :: t()
  def new({o, opts}) when is_atom(o) or is_binary(o), do: new({Util.normalize_module(o), opts})

  def new({{o, name}, opts}) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    opts = opts ++ o.__opts__
    {kind, opts} = Keyword.pop(opts, :kind, :intermediate)
    {attributes, opts} = Keyword.pop(opts, :attributes, attribute(kind))
    async = Keyword.get(opts, :async, false)

    attributes = if async, do: Keyword.merge([style: "bold"], attributes), else: attributes

    %__MODULE__{
      module: o,
      name: name,
      kind: kind,
      __async__: async,
      __opts__: opts,
      __graphviz__: attributes
    }
  end

  @spec start?(t()) :: boolean()
  def start?(%__MODULE__{kind: :start}), do: true
  def start?(%__MODULE__{}), do: false

  @spec end?(t()) :: boolean()
  def end?(%__MODULE__{kind: :end}), do: true
  def end?(%__MODULE__{}), do: false

  @spec validate([t()]) :: [t()]
  def validate(events) do
    if Enum.empty?(events), do: raise(ArgumentError, "Event is empty")

    for %__MODULE__{module: module, name: name} <- events, reduce: [] do
      ary ->
        if name in ary, do: raise(ArgumentError, "Event `#{name}` is defined twice")
        ary ++ [{module, name}, name]
    end

    case Enum.filter(events, &start?/1) do
      [_] -> :ok
      [] -> raise(ArgumentError, "Need a start event")
      [_, _ | _] -> raise(ArgumentError, "Multiple start event found")
    end

    Enum.find(events, &end?/1) || raise(ArgumentError, "Need one or more end event")

    events
  end

  @spec init(Process.t()) :: Process.t() | {:error, term()}
  def init(%Process{events: events} = p) do
    Enum.reduce_while(events, p, fn {key, event}, p ->
      state_change = if event.kind == :start, do: [:initial, :ready], else: [:initial]

      case change(state_change, event, p) do
        {:ok, p} -> {:cont, p}
        {:error, reason} -> {:halt, {key, reason}}
      end
    end)
  end

  @spec do_change(state_change(), t(), Process.t()) :: {:ok, t()} | {:error, term()}
  defp do_change(target_state, %__MODULE__{module: module, state: before_state} = e, p)
       when {before_state, target_state} in @state_changes do
    module.before_change({before_state, target_state}, e, p)
    |> case do
      :ok -> {:ok, %__MODULE__{e | __context__: %Context{state: :ok}}}
      {:ok, %__MODULE__{} = e} -> {:ok, %__MODULE__{e | __context__: %Context{state: :ok}}}
      {:ok, term} -> {:ok, %__MODULE__{e | __context__: %Context{state: :ok, result: term}}}
      {:error, reason} -> {:error, reason}
    end
    |> case do
      {:ok, %__MODULE__{} = e} -> {:ok, %{e | state: List.last(target_state)}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec change(state_change(), t(), Process.t()) :: {:ok, Process.t()} | {:error, term()}
  def change(target_state, %__MODULE__{module: module, name: name, __async__: true} = e, p) do
    f = fn -> do_change(target_state, e, p) end
    p = Process.async(p, f, &callback/4, {module, name})
    {:ok, put_in(p, [:events, {module, name}], %{e | state: :pending})}
  end

  def change(target_state, %__MODULE__{module: module, name: name, __async__: false} = e, p) do
    case do_change(target_state, e, p) do
      {:ok, %__MODULE__{} = e} -> {:ok, put_in(p, [:events, {module, name}], e)}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec callback(Flexflow.key_normalize(), Process.t(), :ok | :error, term) :: Process.result()
  def callback({module, name}, %Process{} = p, :ok, {:ok, %__MODULE__{} = e}) do
    {:ok, put_in(p, [:events, {module, name}], e)}
  end

  def callback({module, name}, %Process{} = p, :ok, {:error, reason}) do
    {:ok, update_in(p, [:events, {module, name}], &handle_error(&1, reason))}
  end

  def callback({module, name}, %Process{} = p, :error, reason) do
    {:ok, update_in(p, [:events, {module, name}], &handle_error(&1, reason))}
  end

  @spec handle_error(t(), term()) :: t()
  defp handle_error(%__MODULE__{} = e, reason) do
    %{e | state: :error, __context__: %Context{state: :error, result: reason}}
  end
end
