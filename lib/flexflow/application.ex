defmodule Flexflow.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [Flexflow.Registry]

    {:ok, pid} =
      Supervisor.start_link(children, strategy: :one_for_one, name: Flexflow.Supervisor)

    :ok = Flexflow.Registry.register_all()

    {:ok, pid}
  end
end
