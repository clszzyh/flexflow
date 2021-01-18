defmodule Flexflow.ProcessManager do
  @moduledoc false

  use DynamicSupervisor
  use Flexflow.ProcessRegistry

  def start_link(module) do
    DynamicSupervisor.start_link(__MODULE__, module, name: via_tuple(module))
  end

  @impl true
  def init(module) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [module])
  end

  @spec server(Flexflow.id(), Flexflow.process_args()) :: {:ok | :exist, pid}
  def server(id, opts \\ %{}) do
    case start_child(id, opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:exist, pid}
    end
  end

  @spec start_child(Flexflow.id(), Flexflow.process_args()) ::
          {:ok, pid} | {:error, {:already_started, pid}}
  defp start_child(id, opts) do
    DynamicSupervisor.start_child(__MODULE__, {Flexflow.ProcessServer, {id, opts}})
  end
end
