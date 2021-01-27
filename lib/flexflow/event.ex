defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Context
  alias Flexflow.Events.{Bypass, End, Start}
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial, :ready, :completed, :pending, :error]
  @state_changes [created: :initial, initial: :ready]

  @typedoc """
  Event state

  #{inspect(@states)}
  """
  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type kind :: :start | :end | :intermediate
  @type options :: Keyword.t()
  @type edge :: {Flexflow.identity(), Flexflow.identity()}
  @type before_change_result :: :ok | {:ok, t()} | {:ok, term()} | {:error, term()}
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          kind: kind(),
          __async__: Keyword.t() | false,
          __graphviz__: Keyword.t(),
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
  @callback before_change({state(), state()}, t(), Process.t()) :: before_change_result()

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok

  @optional_callbacks [validate: 2]

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)
      alias unquote(__MODULE__)

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

  @spec attribute(kind()) :: Keyword.t()
  defp attribute(:intermediate), do: [shape: "box"]
  defp attribute(:start), do: [shape: "doublecircle", color: "\".7 .3 1.0\""]
  defp attribute(:end), do: [shape: "circle", color: "red"]

  def base_module(:start), do: Start
  def base_module(:end), do: End
  def base_module(:intermediate), do: Bypass

  @spec key(t()) :: Flexflow.identity()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({Flexflow.identity_or_module(), options}) :: t()
  def new({o, _opts}) when is_binary(o), do: raise(ArgumentError, "Name `#{o}` should be an atom")
  def new({o, opts}) when is_atom(o), do: new({Util.normalize_module(o), opts})

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
    Enum.reduce_while(events, p, &init_1/2)
  end

  @spec init_1({Flexflow.identity(), t()}, Process.t()) ::
          {:halt, {:error, term()}} | {:cont, Process.t()}
  defp init_1({key, %{kind: :start, module: module, name: name} = event}, p) do
    with {:ok, p} <- change(:initial, event, p),
         {:ok, p} <- change(:ready, get_in(p, [:events, {module, name}]), p) do
      {:cont, p}
    else
      {:error, reason} -> {:halt, {:error, {key, reason}}}
    end
  end

  defp init_1({key, event}, p) do
    case change(:initial, event, p) do
      {:ok, p} -> {:cont, p}
      {:error, reason} -> {:halt, {:error, {key, reason}}}
    end
  end

  @spec change(state(), t(), Process.t()) :: {:ok, Process.t()} | {:error, term()}
  def change(target, %__MODULE__{module: module, name: name, __async__: false} = e, p) do
    case do_change(target, e, p) do
      {:ok, %__MODULE__{} = e} -> {:ok, put_in(p, [:events, {module, name}], e)}
      {:error, reason} -> {:error, reason}
    end
  end

  def change(target, %__MODULE__{module: module, name: name} = e, p) do
    f = fn -> do_change(target, e, p) end
    p = Process.async(p, f, &callback/4, {module, name})
    {:ok, put_in(p, [:events, {module, name}], %{e | state: :pending})}
  end

  @spec do_change(state(), t(), Process.t()) :: {:ok, t()} | {:error, term()}
  defp do_change(target, %__MODULE__{module: module, state: before} = e, p)
       when {before, target} in @state_changes do
    module.before_change({before, target}, e, p)
    |> case do
      :ok -> {:ok, %Context{state: :ok}, e}
      {:ok, %__MODULE__{} = e} -> {:ok, %Context{state: :ok}, e}
      {:ok, term} -> {:ok, %Context{state: :ok, result: term}, e}
      {:error, reason} -> {:error, reason}
    end
    |> case do
      {:ok, %Context{} = ctx, %__MODULE__{} = e} -> {:ok, %{e | state: target, __context__: ctx}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec callback(Flexflow.identity(), Process.t(), :ok | :error, term) :: Process.result()
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
