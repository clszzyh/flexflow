defmodule Flexflow.ProcessStatem do
  @moduledoc """
  gen_statem
  """

  alias Flexflow.Process
  use Flexflow.ProcessRegistry
  require Logger

  @behaviour :gen_statem

  @type handle_event_result ::
          :gen_statem.event_handler_result(Flexflow.state_key())
          | :gen_statem.state_enter_result(Flexflow.state_key())

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(module, {id, opts}) do
    :gen_statem.start_link(via_tuple({module, id}), __MODULE__, {module, id, opts}, [])
  end

  @spec state(Flexflow.process_identity()) :: {:ok, Process.t()}
  def state(identity), do: :gen_statem.call(pid(identity), :state)

  @spec call(Flexflow.process_identity(), term()) :: term()
  def call(identity, op), do: :gen_statem.call(pid(identity), op)

  @spec cast(Flexflow.process_identity(), term()) :: :ok
  def cast(identity, op), do: :gen_statem.cast(pid(identity), op)

  @impl true
  def callback_mode, do: [:handle_event_function, :state_enter]

  @impl true
  @spec init({module(), Flexflow.id(), Flexflow.process_args()}) ::
          :gen_statem.init_result(Flexflow.state_type())
  def init({module, id, opts}) do
    case Process.init(module, id, opts) do
      {:ok, p} -> {:ok, p.state, p}
      {:error, reason} -> {:stop, reason}
    end
  catch
    kind, reason ->
      formatted = Exception.format(kind, reason, __STACKTRACE__)
      {:stop, formatted}
  end

  @impl true
  def handle_event({:call, from}, :state, state, process) do
    {:keep_state_and_data, [{:reply, from, {:ok, %{process | state: state}}}]}
  end

  def handle_event(event, content, state, process) do
    Process.handle_event(event, content, %{process | state: state, __actions__: []})
    |> handle_result(process)
  catch
    kind, reason ->
      formatted = Exception.format(kind, reason, __STACKTRACE__)
      {:stop, formatted, process}
  end

  @impl true
  def terminate(reason, state, %{module: module} = p) do
    Logger.error("Terminated: #{state} #{module}: #{reason}")

    if function_exported?(module, :terminate, 2) do
      module.terminate(reason, %{p | state: state})
    else
      :ok
    end
  end

  @spec handle_result(Process.result(), Process.t()) :: handle_event_result()
  def handle_result({:ok, %Process{state: state} = process}, %Process{state: state}) do
    {:keep_state, process, process.__actions__}
  end

  def handle_result({:ok, %Process{state: state} = process}, _) do
    {:next_state, state, process, process.__actions__}
  end

  def handle_result({:error, reason}, process) do
    {:stop, reason, process}
  end
end
