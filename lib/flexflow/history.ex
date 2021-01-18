defmodule Flexflow.History do
  @moduledoc """
  History
  """

  @type t :: %__MODULE__{
          id: integer(),
          time: integer(),
          msg: String.t()
        }
  @enforce_keys [:id, :time, :msg]
  defstruct @enforce_keys
end
