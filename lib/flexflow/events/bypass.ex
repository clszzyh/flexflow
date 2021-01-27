defmodule Flexflow.Events.Bypass do
  @moduledoc """
  Bypass
  """

  use Flexflow.Event

  @impl true
  def validate(%{__out_edges__: [], __in_edges__: []} = event, _) do
    raise ArgumentError, "`#{inspect(Event.key(event))}` is isolated"
  end

  def validate(_, _), do: :ok
end
