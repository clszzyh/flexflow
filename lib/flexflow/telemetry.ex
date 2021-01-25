defmodule Flexflow.Telemetry do
  @moduledoc """
  Telemetry
  """

  require Logger

  alias Flexflow.History
  alias Flexflow.Process

  @prefix :flexflow
  @handler_id "#{@prefix}-telemetry-logger"

  @event_types [:process_init, :process_loop]

  @events Enum.flat_map(@event_types, fn x ->
            [[@prefix, x, :start], [@prefix, x, :stop], [@prefix, x, :exception]]
          end)

  @type event_type :: unquote(Enum.reduce(@event_types, &{:|, [], [&1, &2]}))

  @spec attach_default_logger(Logger.level()) :: :ok | {:error, :already_exists}
  def attach_default_logger(level \\ :info) do
    :telemetry.attach_many(@handler_id, @events, &handle_logger/4, level)
  end

  @spec attach_history_event(term()) :: :ok
  def attach_history_event(config \\ nil) do
    :telemetry.attach_many(@handler_id, @events, &handle_history/4, config)
  end

  @spec span(event_type(), fun :: (() -> {term(), map()}), meta :: map()) :: term()
  def span(name, fun, meta \\ %{}) when name in @event_types and is_function(fun, 0) do
    :telemetry.span([@prefix, name], meta, fun)
  end

  @spec handle_history([atom()], map(), map(), term()) :: :ok
  def handle_history(
        [@prefix, event, stage],
        measurements,
        %{module: module, id: id} = metadata,
        _config
      )
      when event in @event_types do
    History.put({module, id}, %{
      event: event,
      stage: stage,
      metadata: Map.drop(metadata, [:id, :module]),
      measurements: measurements
    })
  end

  @spec handle_logger([atom()], map(), map(), Logger.level()) :: :ok
  def handle_logger([@prefix, kind, event], _, meta, level) do
    Logger.log(level, "#{kind}-#{event} #{inspect(meta)}")
  end

  @spec invoke_process(Process.t(), atom(), (Process.t() -> Process.result())) :: Process.result()
  def invoke_process(%Process{} = p, name, f) when name in @event_types do
    span(
      name,
      fn ->
        {state, result} = f.(p)
        {{state, result}, %{state: state, id: p.id, module: p.module}}
      end,
      %{id: p.id, module: p.module}
    )
  end
end
