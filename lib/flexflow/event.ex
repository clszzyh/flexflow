defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  def define({o, _opts}) do
    o
  end
end
