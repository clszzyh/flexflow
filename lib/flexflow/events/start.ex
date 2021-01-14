defmodule Flexflow.Events.Start do
  @moduledoc """
  As the name implies, the Start Event indicates where a particular
  Process or Choreography will start.
  """

  use Flexflow.Event

  @impl true
  def name, do: :start
end
