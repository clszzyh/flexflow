defmodule Flexflow.States.End do
  @moduledoc """
  End
  """

  use Flexflow.State

  def type, do: :end

  @impl true
  def graphviz_attribute, do: [shape: "circle", color: "red"]

  @impl true
  def validate(%{__in_edges__: []} = state, _) do
    raise(ArgumentError, "In edges of `#{inspect(State.key(state))}` is empty")
  end

  def validate(_, _), do: :ok
end
