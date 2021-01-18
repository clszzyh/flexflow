defmodule Flexflow.ProcessParentManager do
  @moduledoc false

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def register(module) do
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, {Flexflow.ProcessManager, module})
    :ok
  end

  def children do
    childs = DynamicSupervisor.which_children(__MODULE__)
    for {_, pid, kind, [module]} <- childs, do: %{pid: pid, kind: kind, module: module}
  end
end
