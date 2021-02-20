defmodule Flexflow.State do
  @moduledoc """
  State
  """

  alias Flexflow.Context
  alias Flexflow.Process
  alias Flexflow.States.Blank
  alias Flexflow.Util

  @types [:start, :end, :bypass]

  @type type :: unquote(Enum.reduce(@types, &{:|, [], [&1, &2]}))
  @type options :: Keyword.t()
  @type action_result :: :ok | {:ok, t()} | {:ok, term()} | {:error, term()}
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          type: type(),
          __in_edges__: [Flexflow.state_key()],
          __out_edges__: [Flexflow.state_key()],
          context: Context.t(),
          __opts__: options
        }

  @enforce_keys [:name, :module, :type]
  defstruct @enforce_keys ++
              [
                __in_edges__: [],
                __out_edges__: [],
                __opts__: [],
                context: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()
  @callback type :: type()
  @doc "Invoked after compile, return :ok if valid"
  @callback validate(t(), Process.t()) :: :ok
  @callback init(t(), Process.t()) :: Process.result()
  @callback graphviz_attribute :: keyword()
  @callback handle_leave(t(), Process.t()) :: Process.state_result()
  @callback handle_enter(t(), Process.t()) :: Process.state_result()
  @callback handle_event(Process.event_type(), term(), t(), Process.t()) :: Process.state_result()
  @callback handle_input(Process.event_type(), term(), t(), Process.t()) :: Process.state_result()

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

      defimpl(Flexflow.StateTracker, do: def(ping(_), do: :pong))

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
        defdelegate type, to: unquote(inherit)
        defdelegate validate(s, p), to: unquote(inherit)
        defdelegate init(s, p), to: unquote(inherit)
        defdelegate handle_leave(s, p), to: unquote(inherit)
        defdelegate handle_enter(s, p), to: unquote(inherit)
        defdelegate handle_event(e, c, s, p), to: unquote(inherit)
        defdelegate handle_input(e, c, s, p), to: unquote(inherit)
      end

      defoverridable unquote(__MODULE__)
      Module.delete_attribute(__MODULE__, :__name__)
    end
  end

  @spec key(t()) :: Flexflow.state_key()
  def key(%{name: name}), do: name

  @spec new({Flexflow.state_type_or_module(), options}, Process.process_tuple()) :: t()
  def new({o, _opts}, _) when is_binary(o),
    do: raise(ArgumentError, "Name `#{o}` should be an atom")

  def new({o, opts}, process_tuple) when is_atom(o),
    do: new({Util.normalize_module(o), opts}, process_tuple)

  def new({{o, name}, opts}, process_tuple) do
    unless Util.local_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    opts = opts ++ o.__opts__
    {type, opts} = Keyword.pop(opts, :type, o.type)
    unless type in @types, do: raise(ArgumentError, "Unknown state type #{type}")
    {ast, opts} = Keyword.pop(opts, :do)
    {module, name} = new_module(ast, o, name, process_tuple)

    %__MODULE__{
      module: module,
      name: name,
      type: type,
      __opts__: opts
    }
  end

  def normalize_state_key({_, name}, [_ | _] = states, process_name) do
    Enum.find_value(states, fn %{name: state_name} ->
      if state_name in [name, new_name(name, process_name)], do: state_name
    end) || raise(ArgumentError, "Cannot find #{name}")
  end

  def new_name(name, process_name), do: String.to_atom("#{process_name}_s_#{name}")

  defp new_module(nil, parent_module, name, _), do: {parent_module, name}

  defp new_module(ast, parent_module, name, {process_module, process_name}) do
    module_name = Module.concat([process_module, parent_module, Macro.camelize(to_string(name))])
    name = new_name(name, process_name)

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

  @spec start?(t()) :: boolean()
  def start?(%__MODULE__{type: :start}), do: true
  def start?(%__MODULE__{}), do: false

  @spec end?(t()) :: boolean()
  def end?(%__MODULE__{type: :end}), do: true
  def end?(%__MODULE__{}), do: false

  @spec validate([t()]) :: [t()]
  def validate(states) do
    if Enum.empty?(states), do: raise(ArgumentError, "State is empty")

    for %__MODULE__{name: name} <- states, reduce: [] do
      ary ->
        if name in ary, do: raise(ArgumentError, "State `#{name}` is defined twice")
        [name | ary]
    end

    case Enum.filter(states, &start?/1) do
      [_] -> :ok
      [] -> raise(ArgumentError, "Need a start state")
      [_, _ | _] -> raise(ArgumentError, "Multiple start state found")
    end

    states
  end

  @spec init(Process.t()) :: Process.result()
  def init(%{states: states} = p) do
    Enum.reduce_while(states, p, fn {key, state}, p ->
      case state.module.init(state, p) do
        {:ok, state} -> {:cont, put_in(p, [:states, key], state)}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      %Process{} = p -> {:ok, p}
    end
  end
end

defmodule Flexflow.States.Blank do
  @moduledoc false

  use Flexflow.State

  @impl true
  def name, do: :blank

  @impl true
  def type, do: :bypass

  @impl true
  def init(s, _), do: {:ok, s}

  @impl true
  def validate(%{__out_edges__: [], __in_edges__: []} = state, _) do
    raise ArgumentError, "`#{inspect(State.key(state))}` is isolated"
  end

  def validate(_, _), do: :ok

  @impl true
  def graphviz_attribute, do: []

  @impl true
  def handle_leave(_, p), do: {:ok, p}

  @impl true
  def handle_enter(_, p), do: {:ok, p}

  @impl true
  def handle_event(_, _, _, p), do: {:ok, p}

  @impl true
  def handle_input(_, _, _, p), do: {:ok, p}
end
