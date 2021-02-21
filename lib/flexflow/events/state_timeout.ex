defmodule Flexflow.Events.StateTimeout do
  @moduledoc """
  https://erlang.org/doc/man/gen_statem.html#type-state_timeout
  """
  use Flexflow.Event

  @impl true
  def default_results, do: [:state_timeout]

  @impl true
  def handle_input(_data, _state, _process) do
    {:ok, :state_timeout}
  end

  @impl true
  def handle_result(:state_timeout, :cast, _data, _state, _p) do
    :ignore
  end
end
