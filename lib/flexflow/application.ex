defmodule Flexflow.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [Flexflow.Registry]

    Supervisor.start_link(children, strategy: :one_for_one, name: Flexflow.Supervisor)
  end
end
