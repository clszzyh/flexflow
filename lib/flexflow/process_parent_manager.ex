defmodule Flexflow.ProcessParentManager do
  @moduledoc """
  ProcessParentManager
  """

  use DynamicSupervisor
  alias Flexflow.Tracker

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec register(module()) :: {:ok, pid()} | {:error, term()}
  def register(module) do
    case DynamicSupervisor.start_child(__MODULE__, {Flexflow.ProcessManager, module}) do
      :ignore -> {:error, :ignore}
      {:ok, pid, _info} -> {:ok, pid}
      rest -> rest
    end
  end

  def register_all do
    Tracker.impls()[:processes]
    |> Enum.reduce_while(:ok, fn {module, _}, :ok ->
      case register(module) do
        {:ok, _pid} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def children do
    childs = DynamicSupervisor.which_children(__MODULE__)
    for {_, pid, kind, [module]} <- childs, do: %{pid: pid, kind: kind, module: module}
  end
end
