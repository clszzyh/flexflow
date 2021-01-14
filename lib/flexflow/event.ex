defmodule Flexflow.Event do
  @moduledoc """

  An Event is something that `happens` during the course of a Process
  or a Choreography. These Events affect the flow of the model and
  usually have a cause (Trigger) or an impact (Result). Events are
  circles with open centers to allow internal markers to differentiate
  different Triggers or Results. There are three types of Events,
  based on when they affect the flow: Start, Intermediate, and End.
  """

  def name, do: :event

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
      # @after_compile Flexflow.Registry
    end
  end
end
