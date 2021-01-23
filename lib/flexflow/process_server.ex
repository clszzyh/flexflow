defmodule Flexflow.ProcessServer do
  @moduledoc """
  ProcessServer
  """

  alias Flexflow.Process

  use Flexflow.ProcessRegistry
  use GenServer, restart: :temporary

  def start_link(module, {id, opts}) do
    GenServer.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  def state(srv), do: GenServer.call(srv, :state)

  @impl true
  def init({module, id, opts}) do
    {:ok, Process.new(module, id, opts), {:continue, :init}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(input, from, state) do
    Process.handle_call(state, input, from)
  end

  @impl true
  def handle_cast(input, state) do
    Process.handle_cast(state, input)
  end

  @impl true
  def handle_info(input, state) do
    Process.handle_info(state, input)
  end

  @impl true
  def handle_continue(input, state) do
    Process.handle_continue(state, input)
  end

  @impl true
  def terminate(reason, state) do
    Process.terminate(state, reason)
  end
end
