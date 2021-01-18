defmodule Flexflow.ProcessDynamicSupervisor do
  @moduledoc false

  alias Flexflow.ProcessServer

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec server(Flexflow.process_identity(), Flexflow.process_args()) :: {:ok | :exist, pid}
  def server({module, id}, opts \\ %{}) do
    case start_child({module, id}, opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:exist, pid}
    end
  end

  @spec start_child(Flexflow.process_identity(), Flexflow.process_args()) ::
          {:ok, pid} | {:error, {:already_started, pid}}
  defp start_child({module, id}, opts) do
    DynamicSupervisor.start_child(__MODULE__, {ProcessServer, {{module, id}, opts}})
  end

  def children do
    childs = DynamicSupervisor.which_children(__MODULE__)
    for {_, pid, kind, [module]} <- childs, do: %{pid: pid, kind: kind, module: module}
  end
end
