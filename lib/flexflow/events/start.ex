defmodule Flexflow.Events.Start do
  @moduledoc """
  Start
  """

  use Flexflow.Event, kind: :start

  @impl true
  def validate(%{__out_edges__: []} = event, _) do
    raise(ArgumentError, "Out edges of `#{inspect(Event.key(event))}` is empty")
  end

  def validate(_, _), do: :ok
end
