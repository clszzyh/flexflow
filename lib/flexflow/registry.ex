defmodule Flexflow.Registry do
  @moduledoc false

  use GenServer, restart: :temporary

  alias Flexflow.Util

  @type t :: %__MODULE__{event: %{Flexflow.name() => module()}}
  defstruct event: %{}

  def register(module) do
    case GenServer.call(__MODULE__, {:register, module}) do
      {:error, reason} -> raise ArgumentError, reason
      :ok -> :ok
    end
  end

  def register_all do
    [_ | _] =
      modules =
      for module <- :erlang.loaded(),
          Util.local_behaviour?(module) do
        module
      end

    Enum.each(modules, &register/1)
  end

  def state, do: GenServer.call(__MODULE__, :state)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:register, module}, _from, state) do
    kind = Util.main_behaviour(module).name
    name = module.name()

    case Map.get(state, kind) do
      nil ->
        {:reply, {:error, "Undefined kind #{module.kind()}"}, state}

      %{} = map ->
        case Map.get(map, name) do
          nil ->
            {:reply, :ok, %{state | kind => Map.put(map, name, module)}}

          exists ->
            {:reply, {:error, "Already exists #{name}, #{exists}"}, state}
        end
    end
  end
end
