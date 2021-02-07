defmodule Flexflow.ProcessManager do
  @moduledoc """
  ProcessManager
  """

  use DynamicSupervisor
  use Flexflow.ProcessRegistry

  alias Flexflow.History
  alias Flexflow.ProcessParentManager
  alias Flexflow.ProcessStatem
  alias Flexflow.Util

  @type t :: %__MODULE__{
          pid: pid(),
          id: Flexflow.id(),
          state: Flexflow.state_key(),
          name: Flexflow.name()
        }
  @enforce_keys [:pid, :id, :name, :state]
  defstruct @enforce_keys

  @type server_return :: {:ok | :exist, pid} | {:error, term()}

  def start_link(module) do
    unless Util.local_behaviour(module) == Flexflow.Process do
      raise ArgumentError, "#{module} is not a valid process"
    end

    DynamicSupervisor.start_link(__MODULE__, module, name: via_tuple(module))
  end

  @impl true
  def init(module) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [module])
  end

  @spec server(Flexflow.process_key(), Flexflow.process_args()) :: server_return
  def server({module, id}, opts \\ %{}) do
    case start_child({module, id}, opts) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:exist, pid}

      {:error, :already_exists} ->
        case child_pid({module, id}) do
          nil -> {:error, :not_exist}
          pid -> {:exist, pid}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec server_pid(module) :: {:ok, pid} | {:error, term()}
  def server_pid(module) do
    case pid(module) do
      nil -> ProcessParentManager.register(module)
      pid -> {:ok, pid}
    end
  end

  @spec child_pid(Flexflow.process_key()) :: nil | pid()
  def child_pid({module, id}) do
    ProcessStatem.pid({module, id})
  end

  @spec stop_child(pid | module | nil, Flexflow.process_identity()) :: :ok | {:error, term()}
  def stop_child(srv \\ nil, key)
  def stop_child(nil, {module, id}), do: stop_child(module, {module, id})

  def stop_child(module, child) when is_atom(module) do
    case server_pid(module) do
      {:ok, srv} -> stop_child(srv, child)
      {:error, reason} -> {:error, reason}
    end
  end

  def stop_child(srv, {module, id}) do
    case ProcessStatem.pid({module, id}) do
      nil -> {:error, :child_not_found}
      pid -> stop_child(srv, pid)
    end
  end

  def stop_child(srv, child_pid) when is_pid(srv) and is_pid(child_pid) do
    DynamicSupervisor.terminate_child(srv, child_pid)
  end

  @spec start_child(Flexflow.process_key(), Flexflow.process_args()) ::
          {:ok, pid()} | {:error, term}
  def start_child({module, id}, opts) do
    with {:ok, srv} <- server_pid(module),
         {:ok, _} <- History.ensure_new({module, id}) do
      case DynamicSupervisor.start_child(srv, {ProcessStatem, {id, opts}}) do
        :ignore -> {:error, :ignore}
        {:ok, pid, _info} -> {:ok, pid}
        rest -> rest
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec children(module()) :: [t()]
  def children(mod) do
    {:ok, srv} = server_pid(mod)
    childs = DynamicSupervisor.which_children(srv)

    for {_, pid, :worker, [ProcessStatem]} <- childs do
      {:ok, state, process} = ProcessStatem.state(pid)
      %__MODULE__{pid: pid, id: process.id, state: state, name: process.name}
    end
  end
end
