defmodule Flexflow.Events.End do
  @moduledoc """
  End
  """

  use Flexflow.Event, kind: :end

  @impl true
  def validate(%{__in_edges__: []} = event, _) do
    raise(ArgumentError, "In edges of `#{inspect(Event.key(event))}` is empty")
  end

  def validate(_, _), do: :ok
end
