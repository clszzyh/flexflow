defmodule Flexflow.Transitions.Pass do
  @moduledoc """
  Pass
  """

  use Flexflow.Transition

  @impl true
  def handle_enter(_, _, _), do: :pass
end
