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

  def define({o, {from, to}}, events) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

    if from == to, do: raise(ArgumentError, "#{inspect(from)} cannot target to self!")

    from = events[from] || raise(ArgumentError, "#{inspect(from)} is not defined!")
    to = events[to] || raise(ArgumentError, "#{inspect(to)} is not defined!")

    Graph.Edge.new(from, to, label: o)
  end

  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    transitions
  end
end
