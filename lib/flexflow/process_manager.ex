defmodule Flexflow.ProcessManager do
  @moduledoc false

  use DynamicSupervisor
  use Flexflow.ProcessRegistry

  alias Flexflow.Util

  @type server_return :: {:ok | :exist, pid} | {:error, term()}

  def start_link(module) do
    unless Util.local_behaviour(module) in [Flexflow.Process] do
      raise ArgumentError, "#{module} is not a valid process"
    end

    DynamicSupervisor.start_link(__MODULE__, module, name: via_tuple(module))
  end

  @impl true
  def init(module) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [module])
  end

  @spec server(Flexflow.process_identity(), Flexflow.process_args()) :: server_return
  def server({module, id}, opts \\ %{}) do
    case start_child({module, id}, opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:exist, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec server_pid(module) :: {:ok, pid} | {:error, term()}
  def server_pid(module) do
    case pid(module) do
      nil ->
        Flexflow.ProcessParentManager.register(module)

      pid ->
        {:ok, pid}
    end
  end

  @spec start_child(Flexflow.process_identity(), Flexflow.process_args()) :: server_return
  defp start_child({module, id}, opts) do
    module
    |> server_pid()
    |> case do
      {:ok, srv} -> DynamicSupervisor.start_child(srv, {Flexflow.ProcessSupervisor, {id, opts}})
      {:error, reason} -> {:error, reason}
    end
  end

  def children(mod) do
    {:ok, srv} = server_pid(mod)
    childs = DynamicSupervisor.which_children(srv)
    for {_, pid, kind, [module]} <- childs, do: %{pid: pid, kind: kind, module: module}
  end
end
