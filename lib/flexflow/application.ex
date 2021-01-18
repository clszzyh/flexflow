defmodule Flexflow.Application do
  @moduledoc false

  use Application

  alias Flexflow.Config

  def start(_type, _args) do
    children = [
      Flexflow.ModuleRegistry,
      Flexflow.ProcessRegistry,
      Flexflow.ProcessDynamicSupervisor
    ]

    if Config.get(:telemetry_logger) do
      :ok = Flexflow.Telemetry.attach_default_logger(Config.get(:telemetry_logger_level))
    end

    Supervisor.start_link(children, strategy: :one_for_one, name: Flexflow.Supervisor)
  end
end
