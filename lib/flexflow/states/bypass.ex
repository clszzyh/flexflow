defmodule Flexflow.States.Bypass do
  @moduledoc """
  Bypass
  """

  use Flexflow.State

  @impl true
  def type, do: :bypass

  @impl true
  def graphviz_attribute, do: [shape: "box"]

  @impl true
  def validate(%{__out_edges__: [], __in_edges__: []} = state, _) do
    raise ArgumentError, "`#{inspect(State.key(state))}` is isolated"
  end

  def validate(_, _), do: :ok
end
