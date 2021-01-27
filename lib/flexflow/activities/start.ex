defmodule Flexflow.Activities.Start do
  @moduledoc """
  Start
  """

  use Flexflow.Activity, kind: :start

  @impl true
  def validate(%{__out_edges__: []} = activity, _) do
    raise(ArgumentError, "Out edges of `#{inspect(Activity.key(activity))}` is empty")
  end

  def validate(_, _), do: :ok
end
