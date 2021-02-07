defmodule Flexflow.States.Start do
  @moduledoc """
  Start
  """

  use Flexflow.State

  @impl true
  def type, do: :start

  @impl true
  def graphviz_attribute, do: [shape: "doublecircle", color: "\".7 .3 1.0\""]

  @impl true
  def validate(%{__out_edges__: []} = state, _) do
    raise(ArgumentError, "Out edges of `#{inspect(State.key(state))}` is empty")
  end

  def validate(_, _), do: :ok
end
