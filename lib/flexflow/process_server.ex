defmodule Flexflow.ProcessServer do
  @moduledoc """
  ProcessServer
  """

  alias Flexflow.Process
  alias Flexflow.ProcessManager

  use Flexflow.ProcessRegistry
  use GenServer, restart: :temporary

  def start_link(module, {id, opts}) do
    GenServer.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  @spec call(Flexflow.process_identity(), term()) :: term()
  def call(pid, op) when is_pid(pid), do: GenServer.call(pid, op)
  def call({module, id}, op), do: call(pid({module, id}), op)

  @spec cast(Flexflow.process_identity(), term()) :: :ok
  def cast(pid, op) when is_pid(pid), do: GenServer.cast(pid, op)
  def cast({module, id}, op), do: cast(pid({module, id}), op)

  @spec state(Flexflow.process_identity()) :: Process.t()
  def state(srv), do: call(srv, :state)

  @spec start_child(Flexflow.process_identity(), Flexflow.process_key(), Flexflow.process_args()) ::
          {:ok, pid()} | {:error, term}
  def start_child(srv, {module, id}, args \\ %{}),
    do: call(srv, {:start_child, {module, id}, args})

  @impl true
  def init({module, id, opts}) do
    {:ok, Process.new(module, id, opts), {:continue, :after_init}}
  end

  @impl true
  def handle_call(:state, _from, p), do: {:reply, p, p}

  def handle_call(
        {:start_child, {child_module, child_id}, %{} = args},
        _from,
        %{module: module, id: id, childs: childs, request_id: request_id} = p
      ) do
    case ProcessManager.server(
           {child_module, child_id},
           Map.merge(args, %{parent: {module, id}, request_id: request_id})
         ) do
      {:ok, pid} -> {:reply, {:ok, pid}, %{p | childs: [{child_module, child_id} | childs]}}
      {:exist, pid} -> {:reply, {:error, {:exist, pid}}, p}
      {:error, reason} -> {:reply, {:error, reason}, p}
    end
  end

  def handle_call(input, from, p), do: p |> Process.handle_call(input, from) |> reply_return(p)

  @impl true
  def handle_cast(input, p), do: p |> Process.handle_cast(input) |> noreply_return(p)

  @impl true
  def handle_info(input, p), do: p |> Process.handle_info(input) |> noreply_return(p)

  @impl true
  def terminate(reason, state), do: Process.terminate(state, reason)

  @impl true
  def handle_continue(:after_init, p), do: p |> Process.after_init() |> noreply_return(p)

  defp reply_return({:ok, p}, _p), do: {:reply, p, p}
  defp reply_return({:error, reason}, p), do: {:stop, reason, p}
  defp noreply_return({:ok, p}, _p), do: {:noreply, p}
  defp noreply_return({:error, reason}, p), do: {:stop, reason, p}
end
