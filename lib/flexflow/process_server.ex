defmodule Flexflow.ProcessServer do
  @moduledoc """
  Server
  """

  alias Flexflow.Api

  use Flexflow.ProcessRegistry
  use GenServer

  def start_link(module, {id, opts}) do
    GenServer.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  def state(srv), do: GenServer.call(srv, :state)

  @impl true
  def init({module, id, opts}) do
    module
    |> Api.start(id, opts)
    |> case do
      {:ok, p} -> {:ok, p}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(input, from, %{module: module} = state) do
    module.handle_call(state, input, from)
  end

  @impl true
  def handle_cast(input, %{module: module} = state) do
    module.handle_cast(state, input)
  end

  @impl true
  def handle_info(input, %{module: module} = state) do
    module.handle_info(state, input)
  end

  @impl true
  def terminate(reason, %{module: module} = state) do
    module.terminate(state, reason)
  end
end
