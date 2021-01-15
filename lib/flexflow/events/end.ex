defmodule Flexflow.Events.End do
  @moduledoc """

  As the name implies, the End Event indicates where a Process or
  Choreography will end.

  """

  use Flexflow.Event

  @impl true
  def name, do: :end
end
