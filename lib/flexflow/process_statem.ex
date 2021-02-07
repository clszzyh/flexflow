defmodule Flexflow.ProcessStatem do
  @moduledoc """
  gen_statem
  """

  alias Flexflow.Event
  alias Flexflow.Process
  use Flexflow.ProcessRegistry

  @behaviour :gen_statem

  def start_link(module, {id, opts}) do
    :gen_statem.start_link(via_tuple({module, id}), __MODULE__, {module, id, opts}, [])
  end

  @spec state(Flexflow.process_identity()) :: {:ok, Flexflow.state_type(), Process.t()}
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
    case Process.new(module, id, opts) do
      {:ok, p} -> {:ok, p.start_state, p}
      {:error, reason} -> {:stop, {:error, reason}}
    end
  end

  @impl true
  def handle_event({:call, from}, :state, state, process) do
    {:keep_state_and_data, [{:reply, from, {:ok, state, process}}]}
  end

  def handle_event(event, content, state, process) do
    Event.handle_event(event, content, state, %{process | __actions__: []})
  end

  @impl true
  def terminate(reason, state, %{module: module} = p) do
    if function_exported?(module, :terminate, 3) do
      module.terminate(reason, state, p)
    else
      :ok
    end
  end

  def handle_result({:ok, %Process{} = process}, _process) do
    {:keep_state, process, process.__actions__}
  end

  def handle_result({:error, reason}, process) do
    {:stop, reason, process}
  end
end
