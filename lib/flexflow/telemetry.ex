defmodule Flexflow.Telemetry do
  @moduledoc """
  Telemetry
  """

  require Logger

  alias Flexflow.History
  alias Flexflow.Process

  @prefix :flexflow
  @handler_id "#{@prefix}-telemetry-logger"

  @activity_types [:process_init, :process_loop]

  @activities Enum.flat_map(@activity_types, fn x ->
                [[@prefix, x, :start], [@prefix, x, :stop], [@prefix, x, :exception]]
              end)

  @type activity_type :: unquote(Enum.reduce(@activity_types, &{:|, [], [&1, &2]}))

  @typedoc """
  ## Options

    * `enable_process_history` Enable Process history in `:ets`
    * `telemetry_logger` Enable default logger handler, default `false`
    * `telemetry_logger_level` Logger level, default `debug`
  """
  @type t :: %__MODULE__{
          enable_process_history: boolean(),
          telemetry_logger: boolean(),
          telemetry_logger_level: Logger.level()
        }

  defstruct enable_process_history:
              Application.compile_env(:flexflow, :enable_process_history, true),
            telemetry_logger: Application.compile_env(:flexflow, :telemetry_logger, false),
            telemetry_logger_level:
              Application.compile_env(:flexflow, :telemetry_logger_level, :debug)

  @spec attach_default_handler() :: :ok | {:error, :already_exists}
  def attach_default_handler do
    :telemetry.attach_many(@handler_id, @activities, &handle_activity/4, %__MODULE__{})
  end

  @spec span(activity_type(), fun :: (() -> {term(), map()}), meta :: map()) :: term()
  def span(name, fun, meta \\ %{}) when name in @activity_types and is_function(fun, 0) do
    :telemetry.span([@prefix, name], meta, fun)
  end

  @spec handle_history([atom()], map(), map(), term()) :: :ok
  def handle_history(
        [@prefix, activity, stage],
        measurements,
        %{module: module, id: id} = metadata,
        _config
      )
      when activity in @activity_types do
    History.put({module, id}, %{
      activity: activity,
      stage: stage,
      metadata: Map.drop(metadata, [:id, :module]),
      measurements: measurements
    })
  end

  @spec handle_activity([atom()], map(), map(), t()) :: :ok
  def handle_activity(activity, measurements, meta, config) do
    if config.enable_process_history,
      do: :ok = handle_history(activity, measurements, meta, config)

    if config.telemetry_logger,
      do: :ok = handle_logger(activity, measurements, meta, config.telemetry_logger_level)

    :ok
  end

  @spec handle_logger([atom()], map(), map(), Logger.level()) :: :ok
  def handle_logger([@prefix, kind, activity], _, meta, level) do
    Logger.log(level, "#{kind}-#{activity} #{inspect(meta)}")
  end

  @spec invoke_process(Process.t(), atom(), (Process.t() -> Process.result())) :: Process.result()
  def invoke_process(%Process{} = p, name, f) when name in @activity_types do
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
