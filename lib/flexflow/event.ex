defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  @type t :: %__MODULE__{
          id: integer(),
          time: integer(),
          msg: String.t()
        }
  @enforce_keys [:id, :time, :msg]
  defstruct @enforce_keys
end
