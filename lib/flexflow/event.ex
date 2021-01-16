defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Util

  @type t :: %__MODULE__{
          id: Flexflow.id()
        }

  @enforce_keys [:id]
  defstruct @enforce_keys

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  def define({o, _opts}) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    o
  end
end
