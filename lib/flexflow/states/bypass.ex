defmodule Flexflow.States.Bypass do
  @moduledoc """
  Bypass
  """

  use Flexflow.State

  @impl true
  def graphviz_attribute, do: [shape: "box"]
end
