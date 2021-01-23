defmodule Flexflow.Context do
  @moduledoc """
  Context
  """

  @states [:initial, :ok, :error]
  @typedoc """
  Context state

  #{inspect(@states)}
  """
  @type state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          result: term(),
          state: state()
        }

  defstruct [:result, state: :initial]

  def new, do: %__MODULE__{}
end
