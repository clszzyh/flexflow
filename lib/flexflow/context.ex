defmodule Flexflow.Context do
  @moduledoc """
  Context
  """

  @type state :: :initial
  @type t :: %__MODULE__{
          result: term(),
          state: state()
        }

  defstruct [:result, state: :initial]

  def new, do: %__MODULE__{}
end
