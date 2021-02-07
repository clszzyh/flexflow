defmodule Flexflow.Telemetry do
  @moduledoc """
  Telemetry
  """

  require Logger

  alias Flexflow.History
  alias Flexflow.Process

  @prefix :flexflow
  @handler_id "#{@prefix}-telemetry-logger"

  @state_types [:process_init, :process_loop]

  @states Enum.flat_map(@state_types, fn x ->
            [[@prefix, x, :start], [@prefix, x, :stop], [@prefix, x, :exception]]
          end)

  @type state_type :: unquote(Enum.reduce(@state_types, &{:|, [], [&1, &2]}))

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
    :telemetry.attach_many(@handler_id, @states, &handle_state/4, %__MODULE__{})
  end

  @spec span(state_type(), fun :: (() -> {term(), map()}), meta :: map()) :: term()
  def span(name, fun, meta \\ %{}) when name in @state_types and is_function(fun, 0) do
    :telemetry.span([@prefix, name], meta, fun)
  end

  @spec handle_history([atom()], map(), map(), term()) :: :ok
  def handle_history(
        [@prefix, state, stage],
        measurements,
        %{module: module, id: id} = metadata,
        _config
      )
      when state in @state_types do
    History.put({module, id}, %{
      state: state,
      stage: stage,
      metadata: Map.drop(metadata, [:id, :module]),
      measurements: measurements
    })
  end

  @spec handle_state([atom()], map(), map(), t()) :: :ok
  def handle_state(state, measurements, meta, config) do
    if config.enable_process_history do
      :ok = handle_history(state, measurements, meta, config)
    end

    if config.telemetry_logger do
      :ok = handle_logger(state, measurements, meta, config.telemetry_logger_level)
    end

    :ok
  end

  @spec handle_logger([atom()], map(), map(), Logger.level()) :: :ok
  def handle_logger([@prefix, kind, state], _, meta, level) do
    Logger.log(level, "#{kind}-#{state} #{inspect(meta)}")
  end

  @spec invoke_process(Process.t(), atom(), (Process.t() -> Process.result())) :: Process.result()
  def invoke_process(%Process{} = p, name, f) when name in @state_types do
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
