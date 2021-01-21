defmodule Flexflow.TransitionServer do
  @moduledoc """
  TransitionServer
  """

  use Flexflow.ProcessRegistry
  use GenServer

  def start_link({module, id, child_module, child_name}) do
    GenServer.start_link(__MODULE__, {module, id, child_module, child_name},
      name: via_tuple({module, id, child_module, child_name})
    )
  end

  def state(srv), do: GenServer.call(srv, :state)

  @impl true
  def init({module, id, child_module, child_name}) do
    {:ok, {module, id, child_module, child_name}}
  end
end
