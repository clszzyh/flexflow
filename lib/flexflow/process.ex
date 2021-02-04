defmodule Flexflow.Process do
  @moduledoc """
  Process
  """

  alias Flexflow.Activity
  alias Flexflow.Config
  alias Flexflow.Context
  alias Flexflow.EventDispatcher
  alias Flexflow.Gateway
  alias Flexflow.TaskSupervisor
  alias Flexflow.Telemetry
  alias Flexflow.Util

  @states [:created, :active, :loop, :waiting, :paused]

  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          id: Flexflow.id() | nil,
          state: state(),
          activities: %{Flexflow.identity() => Activity.t()},
          gateways: %{Flexflow.identity() => Gateway.t()},
          parent: Flexflow.process_key(),
          childs: [Flexflow.process_key()],
          request_id: String.t(),
          __args__: Flexflow.process_args(),
          __vsn__: [{module(), term()}],
          __opts__: Keyword.t(),
          __context__: Context.t(),
          __definitions__: [definition],
          __graphviz__: Keyword.t(),
          __listeners__: %{EventDispatcher.listener() => EventDispatcher.listen_result()},
          __loop__: integer(),
          __counter__: integer(),
          __tasks__: %{reference() => term()}
        }

  @typedoc "Init result"
  @type result :: {:ok, t()} | {:error, term()}
  @type definition :: {:activity | :gateway, Flexflow.identity()}

  @enforce_keys [:module, :activities, :gateways, :__definitions__]
  # @derive {Inspect, except: [:__definitions__, :__graphviz__]}
  defstruct @enforce_keys ++
              [
                :name,
                :id,
                :__vsn__,
                :parent,
                :request_id,
                state: :created,
                childs: [],
                __counter__: 0,
                __loop__: 0,
                __graphviz__: [size: "\"4,4\""],
                __args__: %{},
                __tasks__: %{},
                __opts__: [],
                __listeners__: %{},
                __context__: Context.new()
              ]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started, after activities and gateways `init`, see `Flexflow.Api.init/1`"
  @callback init(t()) :: result()
  @doc "Invoked when process child is started"
  @callback init_child(t()) :: result()

  @callback handle_call(t(), term(), GenServer.from()) :: result()
  @callback handle_cast(t(), term()) :: result()
  @callback handle_info(t(), term()) :: result()
  @callback terminate(t(), term()) :: term()

  @optional_callbacks [handle_call: 3, handle_cast: 2, handle_info: 2, terminate: 2]

  def impls do
    {:consolidated, modules} = Flexflow.ProcessTracker.__protocol__(:impls)
    modules
  end

  defmacro __using__(opts) do
    quote do
      alias Flexflow.Activities.{Bypass, End, Start}
      alias Flexflow.Gateways.Pass

      @__opts__ unquote(opts)

      @behaviour unquote(__MODULE__)

      defimpl Flexflow.ProcessTracker do
        def ping(_), do: :pong
      end

      import unquote(__MODULE__), only: [activity: 1, activity: 2, ~>: 2, gateway: 2, gateway: 3]

      for attribute <- [:__activities__, :__gateways__, :__definitions__] do
        Module.register_attribute(__MODULE__, attribute, accumulate: true)
      end

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)

      @__name__ Flexflow.Util.module_name(__MODULE__)

      @impl true
      def name, do: @__name__

      @impl true
      def init(p), do: {:ok, p}

      @impl true
      def init_child(p), do: {:ok, p}

      defoverridable unquote(__MODULE__)
    end
  end

  defmacro activity(key, opts \\ []) do
    quote bind_quoted: [key: key, opts: opts] do
      @__activities__ {key, opts}
      @__definitions__ {:activity, key}
    end
  end

  defmacro gateway(key, tuple, opts \\ []) do
    quote bind_quoted: [key: key, tuple: tuple, opts: opts] do
      @__gateways__ {key, tuple, opts}
      @__definitions__ {:gateway, Tuple.insert_at(tuple, 0, key)}
    end
  end

  def a ~> b, do: {a, b}

  def __after_compile__(env, _bytecode) do
    process = env.module.new()

    for {_, activity} <- process.activities, do: Activity.validate_process(activity, process)
    for {_, gateway} <- process.gateways, do: Gateway.validate_process(gateway, process)

    :ok
  end

  defmacro __before_compile__(env) do
    activities =
      env.module
      |> Module.get_attribute(:__activities__)
      |> Enum.reverse()
      |> Enum.map(&Activity.new/1)
      |> Activity.validate()

    gateways =
      env.module
      |> Module.get_attribute(:__gateways__)
      |> Enum.reverse()
      |> Enum.map(&Gateway.new(&1, activities))
      |> Gateway.validate()

    definitions =
      env.module
      |> Module.get_attribute(:__definitions__)
      |> Enum.reverse()
      |> Enum.map(fn {k, v} -> {k, Util.normalize_module(v, activities)} end)

    new_activities =
      Map.new(activities, fn o ->
        k = Activity.key(o)
        in_edges = for(t <- gateways, t.to == k, do: {Gateway.key(t), t.from})
        out_edges = for(t <- gateways, t.from == k, do: {Gateway.key(t), t.to})

        {k, %{o | __in_edges__: in_edges, __out_edges__: out_edges}}
      end)

    process = %__MODULE__{
      activities: new_activities,
      module: env.module,
      gateways: for(t <- gateways, into: %{}, do: {Gateway.key(t), t}),
      __definitions__: definitions
    }

    quote bind_quoted: [module: __MODULE__, process: Macro.escape(process)] do
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
        special_map = Map.take(args, [:parent, :__graphviz__, :request_id])
        args = Map.drop(args, [:parent, :__graphviz__, :request_id])

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
            :__activities__,
            :__opts__,
            :__gateways__,
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

  @spec init(t()) :: result()
  def init(%__MODULE__{module: module} = p) do
    with %__MODULE__{} = p <- Activity.init(p),
         %__MODULE__{} = p <- Gateway.init(p),
         {:ok, %__MODULE__{} = p} <- module.init(p),
         {:ok, %__MODULE__{} = p} <- module.init_child(p),
         {:ok, %__MODULE__{} = p} <- EventDispatcher.init_register_all(p) do
      {:ok, %{p | state: :active}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec after_init(t()) :: result()
  def after_init(%__MODULE__{} = p) do
    with {:ok, p} <- Telemetry.invoke_process(p, :process_init, &init/1),
         {:ok, p} <- Telemetry.invoke_process(p, :process_loop, &loop/1) do
      {:ok, p}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec handle_call(t(), term(), GenServer.from() | nil) :: result()
  def handle_call(%__MODULE__{module: module} = p, input, from \\ nil) do
    if function_exported?(module, :handle_call, 3) do
      module.handle_call(p, input, from)
    else
      {:ok, p}
    end
  end

  @spec handle_cast(t(), term()) :: result()
  def handle_cast(%__MODULE__{module: module} = p, input) do
    if function_exported?(module, :handle_cast, 2) do
      module.handle_cast(p, input)
    else
      {:ok, p}
    end
  end

  @spec handle_info(t(), term()) :: result()
  def handle_info(p, {ref, result}) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {{f, first_arg}, p} = pop_in(p.__tasks__[ref])
    apply(f, [first_arg, p, :ok, result])
  end

  def handle_info(p, {:DOWN, ref, :process, _monitor_pid, reason}) when is_reference(ref) do
    {{f, first_arg}, p} = pop_in(p.__tasks__[ref])
    apply(f, [first_arg, p, :error, reason])
  end

  def handle_info(%__MODULE__{module: module} = p, input) do
    if function_exported?(module, :handle_info, 2) do
      module.handle_info(p, input)
    else
      {:ok, p}
    end
  end

  @spec terminate(t(), term()) :: term()
  def terminate(%__MODULE__{module: module} = p, reason) do
    if function_exported?(module, :terminate, 2) do
      module.terminate(p, reason)
    else
      :ok
    end
  end

  @spec async(t(), (() -> r), (arg, t(), :ok | :error, r -> result()), arg, Keyword.t()) :: t()
        when arg: term(), r: term()
  def async(%__MODULE__{} = p, f, callback, value, opts \\ [])
      when is_function(f, 0) and is_function(callback, 4) do
    task = Task.Supervisor.async_nolink(TaskSupervisor, f, opts)
    put_in(p.__tasks__[task.ref], {callback, value})
  end

  @spec loop(t()) :: result()
  def loop(%{state: ignore_state} = p) when ignore_state in [:waiting, :paused], do: {:ok, p}
  def loop(%{state: :active} = p), do: loop(%{p | state: :loop, __loop__: 0})

  def loop(%{state: :loop, __loop__: loop, __counter__: counter} = p) do
    case next(%{p | __loop__: loop + 1, __counter__: counter + 1}) do
      {:error, reason} -> {:error, reason}
      {:ok, %{state: :loop} = p} -> loop(p)
      {:ok, p} -> {:ok, p}
    end
  end

  @max_loop_limit Config.get(:max_loop_limit)

  @spec next(t()) :: result()
  def next(%{__loop__: loop}) when loop > @max_loop_limit, do: {:error, :deadlock_found}

  def next(%{activities: activities, gateways: gateways} = p) do
    for {_, %{state: :ready, __out_edges__: [_ | _] = edges} = e} <- activities,
        {t, n} <- edges do
      {e, Map.fetch!(gateways, t), Map.fetch!(activities, n)}
    end
    |> case do
      [] -> {:ok, %{p | state: :waiting}}
      [_ | _] = a -> Enum.reduce(a, {:ok, p}, &Gateway.dispatch/2)
    end
  end
end
