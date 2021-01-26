defmodule Flexflow.Application do
  @moduledoc false

  use Application

  alias Flexflow.Config

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Flexflow.TaskSupervisor},
      Flexflow.History,
      Flexflow.EventDispatcher,
      Flexflow.ProcessRegistry,
      Flexflow.ProcessParentManager,
      Flexflow.ModuleRegistry
    ]

    if Config.get(:telemetry_default_handler) do
      :ok = Flexflow.Telemetry.attach_default_handler()
    end

    Supervisor.start_link(children, strategy: :one_for_one, name: Flexflow.Supervisor)
  end
end
