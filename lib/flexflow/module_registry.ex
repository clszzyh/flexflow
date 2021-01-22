defmodule Flexflow.ModuleRegistry do
  @moduledoc false

  use GenServer, restart: :temporary

  alias Flexflow.Util

  @state %{
    Flexflow.Event => %{},
    Flexflow.Transition => %{},
    Flexflow.Process => %{}
  }

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def register(module) do
    GenServer.cast(__MODULE__, {:register, module})
  end

  def find(module, name) do
    GenServer.call(__MODULE__, {:find, {module, name}})
  end

  def state, do: GenServer.call(__MODULE__, :state)

  @impl true
  def init(_) do
    {:ok, @state, {:continue, :register_all}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:find, {module, name}}, _from, state) do
    {:reply, get_in(state, [module, name]), state}
  end

  def register(module, state) do
    kind = Util.local_behaviour(module)
    name = module.name()

    {:ok, _} =
      if kind == Flexflow.Process do
        Flexflow.ProcessParentManager.register(module)
      else
        {:ok, :ignore}
      end

    case Map.get(state, kind) do
      nil ->
        {:halt, "Undefined kind #{module.kind()}"}

      %{} = map ->
        case Map.get(map, name) do
          nil -> {:cont, %{state | kind => Map.merge(map, %{name => module})}}
          exists -> {:halt, "Already exists #{name}, #{exists}"}
        end
    end
  end

  @impl true
  def handle_continue(:register_all, state) do
    [_ | _] = modules = Util.implement_modules()

    modules
    |> Enum.reduce_while(state, &register/2)
    |> case do
      {:error, reason} -> {:stop, reason, state}
      state -> {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    IO.puts(inspect({:terminate, reason, state}))
    System.stop(1)
  end
end
