defmodule Flexflow.ProcessServer do
  @moduledoc """
  ProcessServer
  """

  alias Flexflow.History
  alias Flexflow.Process

  use Flexflow.ProcessRegistry
  use GenServer, restart: :temporary

  def start_link(module, {id, opts}) do
    GenServer.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  def state(srv), do: GenServer.call(srv, :state)

  @impl true
  def init({module, id, opts}) do
    case History.ensure_new({module, id}) do
      {:ok, _} -> {:ok, Process.new(module, id, opts), {:continue, :after_init}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call(:state, _from, p), do: {:reply, p, p}
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
