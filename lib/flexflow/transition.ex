defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Util

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

  def define({o, tuple}) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    tuple
  end
end
