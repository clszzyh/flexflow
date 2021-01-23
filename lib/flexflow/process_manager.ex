defmodule Flexflow.ProcessManager do
  @moduledoc """
  ProcessManager
  """

  use DynamicSupervisor
  use Flexflow.ProcessRegistry

  alias Flexflow.Process
  alias Flexflow.ProcessParentManager
  alias Flexflow.ProcessServer
  alias Flexflow.Util

  @type t :: %__MODULE__{
          pid: pid(),
          id: Flexflow.id(),
          name: Flexflow.name()
        }
  @enforce_keys [:pid, :id, :name]
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

  @spec server(Flexflow.process_identity(), Flexflow.process_args()) :: server_return
  def server({module, id}, opts \\ %{}) do
    case start_child({module, id}, opts) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:exist, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec call(Flexflow.process_identity(), term()) :: term()
  def call({module, id}, op) do
    GenServer.call(child_pid({module, id}), op)
  end

  @spec cast(Flexflow.process_identity(), term()) :: :ok
  def cast({module, id}, op) do
    GenServer.cast(child_pid({module, id}), op)
  end

  @spec state(Flexflow.process_identity()) :: Process.t()
  def state({module, id}), do: call({module, id}, :state)

  @spec server_pid(module) :: {:ok, pid} | {:error, term()}
  def server_pid(module) do
    case pid(module) do
      nil -> ProcessParentManager.register(module)
      pid -> {:ok, pid}
    end
  end

  @spec child_pid(Flexflow.process_identity()) :: nil | pid()
  def child_pid({module, id}) do
    ProcessServer.pid({module, id})
  end

  @spec start_child(Flexflow.process_identity(), Flexflow.process_args()) :: server_return
  defp start_child({module, id}, opts) do
    module
    |> server_pid()
    |> case do
      {:ok, srv} -> DynamicSupervisor.start_child(srv, {ProcessServer, {id, opts}})
      {:error, reason} -> {:error, reason}
    end
  end

  @spec children(module()) :: [t()]
  def children(mod) do
    {:ok, srv} = server_pid(mod)
    childs = DynamicSupervisor.which_children(srv)

    for {_, pid, :worker, [ProcessServer]} <- childs do
      process = ProcessServer.state(pid)
      %__MODULE__{pid: pid, id: process.id, name: process.name}
    end
  end
end
