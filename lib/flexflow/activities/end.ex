defmodule Flexflow.Activities.End do
  @moduledoc """
  End
  """

  use Flexflow.Activity, kind: :end

  @impl true
  def graphviz_attribute, do: [shape: "circle", color: "red"]

  @impl true
  def validate(%{__in_edges__: []} = activity, _) do
    raise(ArgumentError, "In edges of `#{inspect(Activity.key(activity))}` is empty")
  end

  def validate(_, _), do: :ok
end
