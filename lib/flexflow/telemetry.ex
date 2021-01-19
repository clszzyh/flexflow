defmodule Flexflow.Telemetry do
  @moduledoc """
  Telemetry
  """

  require Logger

  @prefix :flexflow
  @handler_id "#{@prefix}-telemetry-logger"

  @event_types [:process_init, :process_loop]

  @events Enum.flat_map(@event_types, fn x ->
            [
              [@prefix, x, :start],
              [@prefix, x, :stop],
              [@prefix, x, :exception]
            ]
          end)

  @spec attach_default_logger(Logger.level()) :: :ok | {:error, :already_exists}
  def attach_default_logger(level \\ :info) do
    :telemetry.attach_many(@handler_id, @events, &handle_event/4, level)
  end

  @spec span(atom(), fun :: (() -> {term(), map()}), meta :: map()) :: term()
  def span(name, fun, meta \\ %{}) when name in @event_types and is_function(fun, 0) do
    :telemetry.span([@prefix, name], meta, fun)
  end

  @spec handle_event([atom()], map(), map(), Logger.level()) :: :ok
  def handle_event([@prefix, kind, event], _, meta, level) do
    Logger.log(level, "#{kind}-#{event} #{inspect(meta)}")
  end
end
