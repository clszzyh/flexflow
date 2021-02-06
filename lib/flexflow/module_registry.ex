defmodule Flexflow.ModuleRegistry do
  @moduledoc """
  ModuleRegistry
  """

  use GenServer, restart: :temporary

  alias Flexflow.Activity
  alias Flexflow.Event
  alias Flexflow.Process
  alias Flexflow.Util

  require Logger

  @state %{
    Activity => %{},
    Event => %{},
    Process => %{}
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

    {_, _} =
      if kind == Process do
        Flexflow.ProcessParentManager.register(module)
      else
        {:ok, :ignore}
      end

    case Map.get(state, kind) do
      nil ->
        {:halt, {:error, "Undefined kind #{module.kind()}"}}

      %{} = map ->
        case Map.get(map, name) do
          nil -> {:cont, %{state | kind => Map.merge(map, %{name => module})}}
          exists -> {:halt, {:error, "Already exists #{name}, #{exists}"}}
        end
    end
  end

  @impl true
  def handle_continue(:register_all, state) do
    [_ | _] =
      modules =
      if Mix.env() == :test do
        Util.implement_modules()
      else
        Process.impls() ++ Activity.impls() ++ Event.impls()
      end

    modules
    |> Enum.reduce_while(state, &register/2)
    |> case do
      {:error, reason} -> {:stop, reason, state}
      %{} = state -> {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    Logger.error(inspect({:terminate, reason, state}))
    System.stop(1)
  end
end
