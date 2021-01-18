defmodule Flexflow.ProcessServer do
  @moduledoc """
  Server
  """

  alias Flexflow.Process

  use Flexflow.ProcessRegistry
  use GenServer

  def start_link(module, {id, opts}) do
    GenServer.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  @impl true
  def init({module, id, opts}) do
    p = Process.start(module, id, opts)
    {:ok, p}
  end
end
