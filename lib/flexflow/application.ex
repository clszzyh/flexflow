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
      Flexflow.ProcessParentManager
    ]

    if Config.get(:telemetry_default_handler) do
      :ok = Flexflow.Telemetry.attach_default_handler()
    end

    with {:ok, pid} <-
           Supervisor.start_link(children, strategy: :one_for_one, name: Flexflow.Supervisor),
         :ok <- Flexflow.ProcessParentManager.register_all(),
         :ok <- Flexflow.Tracker.ensure_unique() do
      {:ok, pid}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
