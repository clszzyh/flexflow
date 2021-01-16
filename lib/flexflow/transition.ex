defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Event
  alias Flexflow.Util

  alias Graph.Edge

  @type t :: %__MODULE__{
          module: module(),
          opts: keyword(),
          from: Flexflow.event_key_normalize(),
          to: Flexflow.event_key_normalize()
        }

  @type edge :: Edge.t()

  @enforce_keys [:module, :from, :to]
  defstruct @enforce_keys ++ [opts: []]

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  @spec define({module(), {Flexflow.event_key(), Flexflow.event_key()}, keyword()}, %{
          Flexflow.event_key_normalize() => Event.t()
        }) :: edge()
  def define({o, {from, to}, opts}, events) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

    if from == to, do: raise(ArgumentError, "#{inspect(from)} cannot target to self!")

    new_from = events[from] || raise(ArgumentError, "#{inspect(from)} is not defined!")
    new_to = events[to] || raise(ArgumentError, "#{inspect(to)} is not defined!")

    Edge.new(new_from, new_to, label: %__MODULE__{module: o, opts: opts, from: from, to: to})
  end

  @spec validate([edge()]) :: [edge()]
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    transitions
  end
end
