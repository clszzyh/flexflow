defmodule Flexflow.Server do
  @moduledoc """
  Server
  """

  use Flexflow.ProcessRegistry
  use GenServer

  def start_link({name, opts}) do
    GenServer.start_link(__MODULE__, {name, opts}, name: via_tuple(name))
  end

  @impl true
  def init({name, _opts}) do
    {:ok, name}
  end
end
