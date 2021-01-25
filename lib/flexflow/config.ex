defmodule Flexflow.Config do
  @default_map %{
    max_loop_limit: 1000,
    telemetry_logger: false,
    telemetry_logger_level: :debug
  }

  str = Enum.map_join(@default_map, "\n", fn {k, v} -> "* #{k}: #{v}" end)

  @moduledoc """
  ## Default value:

  #{str}
  """

  def get(key) when is_map_key(@default_map, key) do
    Application.get_env(:flexflow, key, Map.fetch!(@default_map, key))
  end

  def get(key, default), do: Application.get_env(:flexflow, key, default)
end
