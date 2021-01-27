defmodule Flexflow.Activities.Bypass do
  @moduledoc """
  Bypass
  """

  use Flexflow.Activity

  @impl true
  def graphviz_attribute, do: [shape: "box"]

  @impl true
  def validate(%{__out_edges__: [], __in_edges__: []} = activity, _) do
    raise ArgumentError, "`#{inspect(Activity.key(activity))}` is isolated"
  end

  def validate(_, _), do: :ok
end
