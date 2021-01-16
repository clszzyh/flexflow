defmodule Flexflow.Config do
  @default_map %{
    telemetry_logger: true,
    telemetry_logger_level: :debug
  }

  @moduledoc """
  Default Map:
  #{inspect(@default_map, struct: true)}
  """

  def get(key) when is_map_key(@default_map, key) do
    Application.get_env(:flexflow, key, Map.fetch!(@default_map, key))
  end

  def get(key, default), do: Application.get_env(:flexflow, key, default)
end
