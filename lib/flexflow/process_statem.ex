defmodule Flexflow.ProcessStatem do
  @moduledoc """
  gen_statem
  """

  alias Flexflow.Process
  use Flexflow.ProcessRegistry

  @type state_type :: Flexflow.identity()

  @behaviour :gen_statem

  def start_link(module, {id, opts}) do
    :gen_statem.start_link(via_tuple({module, id}), __MODULE__, {module, id, opts}, [])
  end

  @impl true
  def callback_mode, do: [:handle_event_function, :state_enter]

  @impl true
  @spec init({module(), Flexflow.id(), Flexflow.process_args()}) ::
          :gen_statem.init_result(state_type)
  def init({module, id, opts}) do
    case Process.new(module, id, opts) do
      {:ok, p} -> {:ok, p.start_activity, p}
      {:error, reason} -> {:stop, {:error, reason}}
    end
  end

  @impl true
  def terminate(reason, state, %{module: module} = p) do
    if function_exported?(module, :terminate, 3) do
      module.terminate(reason, state, p)
    else
      :ok
    end
  end
end
