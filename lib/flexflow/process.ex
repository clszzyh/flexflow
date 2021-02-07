defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Context
  alias Flexflow.Event
  alias Flexflow.EventDispatcher
  alias Flexflow.State
  alias Flexflow.Util

  @type action :: :gen_statem.action()
  @type event_type :: :gen_statem.event_type()

  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          id: Flexflow.id() | nil,
          start_state: Flexflow.state_type(),
          states: %{Flexflow.state_type() => State.t()},
          events: %{Flexflow.state_type() => Event.t()},
          parent: Flexflow.process_key(),
          childs: [Flexflow.process_key()],
          request_id: String.t(),
          __args__: Flexflow.process_args(),
          __vsn__: [{module(), term()}],
          __opts__: Keyword.t(),
          __context__: Context.t(),
          __definitions__: [definition],
          __actions__: [action],
          __listeners__: %{EventDispatcher.listener() => EventDispatcher.listen_result()},
          __loop__: integer(),
          __counter__: integer(),
          __tasks__: %{reference() => term()}
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type definition :: {:state | :event, Flexflow.state_type()}
  @type process_tuple :: {module(), Flexflow.name()}

  @enforce_keys [:module, :states, :events, :start_state, :__definitions__]
  # @derive {Inspect, except: [:__definitions__]}
  defstruct @enforce_keys ++
              [
                :name,
                :id,
                :__vsn__,
                :parent,
                :request_id,
                childs: [],
                __counter__: 0,
                __loop__: 0,
                __args__: %{},
                __tasks__: %{},
                __opts__: [],
                __actions__: [],
                __listeners__: %{},
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Events.Pass
      alias Flexflow.States.{Bypass, End, Start}

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      defimpl Flexflow.ProcessTracker do
        def ping(_), do: :pong
      end

      import unquote(__MODULE__),
        only: [state: 1, state: 2, state: 3, ~>: 2, event: 2, event: 3, event: 4]

      for attribute <- [:__states__, :__events__, :__definitions__] do
        Module.register_attribute(__MODULE__, attribute, accumulate: true)
      end

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro state(key), do: defstate(key, [])
  defmacro state(key, opts), do: defstate(key, opts)
  defmacro state(key, opts, block), do: defstate(key, opts ++ block)

  defmacro event(key, tuple), do: defevent(key, tuple, [])
  defmacro event(key, tuple, opts), do: defevent(key, tuple, opts)
  defmacro event(key, tuple, opts, block), do: defevent(key, tuple, opts ++ block)

  defp defstate(key, opts) do
    quote bind_quoted: [key: key, opts: Macro.escape(opts)] do
      @__states__ {key, opts}
      @__definitions__ {:state, key}
    end
  end

  defp defevent(key, tuple, opts) do
    quote bind_quoted: [key: key, tuple: tuple, opts: Macro.escape(opts)] do
      @__events__ {key, tuple, opts}
      @__definitions__ {:event, Tuple.insert_at(tuple, 0, key)}
    end
  end

  def a ~> b, do: {a, b}

  def __after_compile__(env, _bytecode) do
    process = env.module.new()

    for map <- [process.states, process.events], {_, %{module: module} = state} <- map do
      :ok = module.validate(state, process)
    end
  end

  defp new_process(env) do
    states =
      env.module
      |> Module.get_attribute(:__states__)
      |> Enum.reverse()
      |> Enum.map(&State.new(&1, {env.module, Module.get_attribute(env.module, :__name__)}))
      |> State.validate()

    events =
      env.module
      |> Module.get_attribute(:__events__)
      |> Enum.reverse()
      |> Enum.map(
        &Event.new(&1, states, {env.module, Module.get_attribute(env.module, :__name__)})
      )
      |> Event.validate()

    definitions =
      env.module
      |> Module.get_attribute(:__definitions__)
      |> Enum.reverse()
      |> Enum.map(fn {k, v} -> {k, Util.normalize_module(v, states)} end)

    new_states =
      Map.new(states, fn o ->
        k = State.key(o)
        in_edges = for(t <- events, t.to == k, do: t.from)
        out_edges = for(t <- events, t.from == k, do: t.to)

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    %__MODULE__{
      states: new_states,
      module: env.module,
      start_state: Enum.find_value(states, fn a -> if State.start?(a), do: State.key(a) end),
      events: for(t <- events, into: %{}, do: {Event.key(t), t}),
      __definitions__: definitions
    }
  end

  defmacro __before_compile__(env) do
    quote bind_quoted: [module: __MODULE__, process: Macro.escape(new_process(env))] do
      alias Flexflow.Process

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{module}`

        #{inspect(process)}
        """
      end

      @__process__ %{process | __opts__: @__opts__}
      @__vsn__ (for {_k, {m, _id}} <- @__process__.__definitions__, uniq: true do
                  {m, m.module_info(:attributes)[:vsn]}
                end) ++ [{:flexflow, Mix.Project.config()[:version]}]

      def __vsn__ do
        [{__MODULE__, __MODULE__.module_info(:attributes)[:vsn]} | @__vsn__]
      end

      @spec new(Flexflow.id(), Flexflow.process_args()) :: Process.t()
      def new(id \\ Flexflow.Util.make_id(), args \\ %{}) do
        special_map = Map.take(args, [:parent, :request_id])
        args = Map.drop(args, [:parent, :request_id])

        struct!(
          @__process__,
          Map.merge(
            %{
              name: name(),
              id: id,
              request_id: Util.random(),
              __vsn__: :crypto.hash(:md5, :erlang.term_to_binary(__vsn__())),
              __args__: args
            },
            special_map
          )
        )
      end

      for attribute <- [
            :__states__,
            :__opts__,
            :__events__,
            :__definitions__,
            :__vsn__,
            :__module__,
            :__name__,
            :__process__
          ] do
        Module.delete_attribute(__MODULE__, attribute)
      end
    end
  end

  @behaviour Access
  @impl true
  def fetch(struct, k), do: Map.fetch(struct, k)
  @impl true
  def get_and_update(struct, k, f) when is_function(f, 1), do: Map.get_and_update(struct, k, f)
  @impl true
  def pop(struct, k), do: Map.pop(struct, k)

  ###### Api ######

  @spec new(module(), Flexflow.id(), Flexflow.process_args()) :: result()
  def new(module, id, args \\ %{}), do: module.new(id, args)

  @spec handle_event(:enter, Flexflow.state_type(), Flexflow.state_type(), t()) :: result
  @spec handle_event(event_type(), term, Flexflow.state_type(), t()) :: result
  def handle_event(:enter, {from_module, _} = from, {to_module, _} = to, process) do
    t = process.events[{from, to}]

    with {:ok, process} <- from_module.handle_leave(process.states[from], process),
         {:ok, process} <- t.module.handle_enter(t, process),
         {:ok, process} <- to_module.handle_enter(process.states[to], process) do
      {:ok, process}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_event(_event_type, _content, _state, process) do
    {:ok, process}
  end
end
