defmodule Flexflow.State do
  @moduledoc """
  State
  """

  alias Flexflow.Context
  alias Flexflow.States.{Bypass, End, Start}
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial, :ready, :completed, :pending, :error]
  @state_changes [created: :initial, initial: :ready]
  @types [:start, :end, :bypass]
  @type_map %{
    start: Start,
    end: End,
    bypass: Bypass
  }

  @typedoc """
  State state

  #{inspect(@states)}
  """
  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type type :: unquote(Enum.reduce(@types, &{:|, [], [&1, &2]}))
  @type options :: Keyword.t()
  @type edge :: {Flexflow.state_type(), Flexflow.state_type()}
  @type action_result :: :ok | {:ok, t()} | {:ok, term()} | {:error, term()}
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          type: type(),
          __async__: Keyword.t() | false,
          __graphviz__: Keyword.t(),
          __in_edges__: [edge()],
          __out_edges__: [edge()],
          __context__: Context.t(),
          __opts__: options
        }

  @enforce_keys [:name, :module, :type]
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

  @doc "State type"
  @callback type :: type()

  @doc "Invoked before state state changes"
  @callback action({state(), state()}, t(), Process.t()) :: action_result()

  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok

  @callback graphviz_attribute :: keyword()

  def impls do
    {:consolidated, modules} = Flexflow.StateTracker.__protocol__(:impls)
    modules
  end

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)
      alias unquote(__MODULE__)

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      defimpl Flexflow.StateTracker do
        def ping(_), do: :pong
      end

      @__name__ Flexflow.Util.module_name(__MODULE__)
      def __opts__, do: unquote(opts)

      @impl true
      def name, do: @__name__
      @impl true
      def graphviz_attribute, do: []
      @impl true
      def validate(_, _), do: :ok

      @impl true
      def action(_, _, _), do: :ok

      defoverridable unquote(__MODULE__)

      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: Flexflow.state_type()
  def key(%{module: module, name: name}), do: {module, name}

  @spec new({Flexflow.state_type_or_module(), options}, module()) :: t()
  def new({o, _opts}, _) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, opts}, process_module) when is_atom(o),
    do: new({Util.normalize_module(o), opts}, process_module)

  def new({{o, name}, opts}, process_module) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    opts = opts ++ o.__opts__
    {type, opts} = Keyword.pop(opts, :type, o.type)
    unless type in @types, do: raise(ArgumentError, "Unknown state type #{type}")
    {attributes, opts} = Keyword.pop(opts, :attributes, @type_map[type].graphviz_attribute())
    {ast, opts} = Keyword.pop(opts, :do)
    module = new_module(ast, o, name, process_module)

    async = Keyword.get(opts, :async, false)

    attributes = if async, do: Keyword.merge([style: "bold"], attributes), else: attributes

    %__MODULE__{
      module: module,
      name: name,
      type: type,
      __async__: async,
      __opts__: opts,
      __graphviz__: attributes
    }
  end

  defp new_module(nil, parent_module, _, _), do: parent_module

  defp new_module(ast, parent_module, name, process_module) do
    module_name = Module.concat([process_module, parent_module, Macro.camelize(to_string(name))])

    ast =
      quote generated: true do
        use unquote(__MODULE__)

        unquote(ast)

        @impl true
        def type, do: :bypass

        @impl true
        def name, do: unquote(name)

        @impl true
        def validate(e, p), do: unquote(parent_module).validate(e, p)
      end

    {:module, ^module_name, _byte_code, _} =
      Module.create(module_name, ast, Macro.Env.location(__ENV__))

    module_name
  end

  @spec start?(t()) :: boolean()
  def start?(%__MODULE__{type: :start}), do: true
  def start?(%__MODULE__{}), do: false

  @spec end?(t()) :: boolean()
  def end?(%__MODULE__{type: :end}), do: true
  def end?(%__MODULE__{}), do: false

  @spec validate([t()]) :: [t()]
  def validate(states) do
    if Enum.empty?(states), do: raise(ArgumentError, "State is empty")

    for %__MODULE__{module: module, name: name} <- states, reduce: [] do
      ary ->
        if name in ary, do: raise(ArgumentError, "State `#{name}` is defined twice")
        ary ++ [{module, name}, name]
    end

    case Enum.filter(states, &start?/1) do
      [_] -> :ok
      [] -> raise(ArgumentError, "Need a start state")
      [_, _ | _] -> raise(ArgumentError, "Multiple start state found")
    end

    Enum.find(states, &end?/1) || raise(ArgumentError, "Need one or more end state")

    states
  end

  @spec init(Process.t()) :: Process.t() | {:error, term()}
  def init(%Process{states: states} = p) do
    Enum.reduce_while(states, p, &init_1/2)
  end

  @spec init_1({Flexflow.state_type(), t()}, Process.t()) ::
          {:halt, {:error, term()}} | {:cont, Process.t()}
  defp init_1({key, %{type: :start, module: module, name: name} = state}, p) do
    with {:ok, p} <- change(:initial, state, p),
         {:ok, p} <- change(:ready, get_in(p, [:states, {module, name}]), p) do
      {:cont, p}
    else
      {:error, reason} -> {:halt, {:error, {key, reason}}}
    end
  end

  defp init_1({key, state}, p) do
    case change(:initial, state, p) do
      {:ok, p} -> {:cont, p}
      {:error, reason} -> {:halt, {:error, {key, reason}}}
    end
  end

  @spec change(state(), t(), Process.t()) :: {:ok, Process.t()} | {:error, term()}
  def change(target, %__MODULE__{module: module, name: name, __async__: false} = e, p) do
    case do_change(target, e, p) do
      {:ok, %__MODULE__{} = e} -> {:ok, put_in(p, [:states, {module, name}], e)}
      {:error, reason} -> {:error, reason}
    end
  end

  def change(target, %__MODULE__{module: module, name: name} = e, p) do
    f = fn -> do_change(target, e, p) end
    p = Process.async(p, f, &callback/4, {module, name})
    {:ok, put_in(p, [:states, {module, name}], %{e | state: :pending})}
  end

  @spec do_change(state(), t(), Process.t()) :: {:ok, t()} | {:error, term()}
  defp do_change(target, %__MODULE__{module: module, state: before} = e, p)
       when {before, target} in @state_changes do
    module.action({before, target}, e, p)
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

  @spec callback(Flexflow.state_type(), Process.t(), :ok | :error, term) :: Process.result()
  def callback({module, name}, %Process{} = p, :ok, {:ok, %__MODULE__{} = e}) do
    {:ok, put_in(p, [:states, {module, name}], e)}
  end

  def callback({module, name}, %Process{} = p, :ok, {:error, reason}) do
    {:ok, update_in(p, [:states, {module, name}], &handle_error(&1, reason))}
  end

  def callback({module, name}, %Process{} = p, :error, reason) do
    {:ok, update_in(p, [:states, {module, name}], &handle_error(&1, reason))}
  end

  @spec handle_error(t(), term()) :: t()
  defp handle_error(%__MODULE__{} = e, reason) do
    %{e | state: :error, __context__: %Context{state: :error, result: reason}}
  end
end