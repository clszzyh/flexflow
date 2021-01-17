defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Node
  alias Flexflow.Util
  alias Graph.Edge

  @type t :: %__MODULE__{
          module: module(),
          opts: keyword(),
          from: Flexflow.node_key_normalize(),
          to: Flexflow.node_key_normalize()
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

  @spec define({module(), {Flexflow.node_key(), Flexflow.node_key()}, keyword()}, %{
          Flexflow.node_key_normalize() => Node.t()
        }) :: edge()
  def define({o, {from, to}, opts}, nodes) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

    if from == to, do: raise(ArgumentError, "#{inspect(from)} cannot target to self!")

    _new_from = nodes[from] || raise(ArgumentError, "#{inspect(from)} is not defined!")
    _new_to = nodes[to] || raise(ArgumentError, "#{inspect(to)} is not defined!")

    Edge.new(from, to, label: %__MODULE__{module: o, opts: opts, from: from, to: to})
  end

  @spec validate([edge()]) :: [edge()]
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    for %Edge{v1: v1, v2: v2} <-
          transitions,
        reduce: [] do
      ary ->
        o = {v1, v2}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    transitions
  end
end
