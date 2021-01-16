defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  @type t :: %__MODULE__{
          name: String.t()
        }

  @enforce_keys [:name]
  defstruct @enforce_keys

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  def define({_o, tuple}), do: tuple
end
