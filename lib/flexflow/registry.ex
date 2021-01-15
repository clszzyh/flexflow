defmodule Flexflow.Registry do
  @moduledoc false

  use GenServer, restart: :temporary

  alias Flexflow.Util

  @type t :: %__MODULE__{event: %{Flexflow.name() => module()}}
  defstruct event: %{}

  def register(module) do
    GenServer.cast(__MODULE__, {:register, module})
  end

  def state, do: GenServer.call(__MODULE__, :state)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}, {:continue, :register_all}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:register, module}, state) do
    kind = Util.main_behaviour(module).name
    name = module.name()

    case Map.get(state, kind) do
      nil ->
        {:stop, "Undefined kind #{module.kind()}", state}

      %{} = map ->
        case Map.get(map, name) do
          nil -> {:noreply, %{state | kind => Map.put(map, name, module)}}
          exists -> {:stop, "Already exists #{name}, #{exists}", state}
        end
    end
  end

  @impl true
  def handle_continue(:register_all, state) do
    [_ | _] =
      modules = for module <- Util.local_modules(), Util.local_behaviour?(module), do: module

    :ok = Enum.each(modules, &register/1)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    IO.puts(inspect({:terminate, reason, state}))
    System.stop(1)
    # :ok
  end
end
