defmodule Flexflow.Transition do
  @moduledoc """
  Transition
  """

  alias Flexflow.Util
  alias Graph.Edge

  @type t :: %__MODULE__{
          module: module(),
          id: Flexflow.id(),
          opts: keyword(),
          from: Flexflow.key_normalize(),
          to: Flexflow.key_normalize()
        }

  @type edge :: Edge.t()
  @type edge_map :: %{edge => t()}

  @enforce_keys [:id, :module, :from, :to]
  defstruct @enforce_keys ++ [opts: []]

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  @spec define({Flexflow.key(), {Flexflow.key(), Flexflow.key()}, keyword()}, Flexflow.nodes()) ::
          {edge(), t()}
  def define({o, {from, to}, opts}, nodes) when is_atom(o),
    do: define({Util.normalize_module(o), {from, to}, opts}, nodes)

  def define({{o, id}, {from, to}, opts}, nodes) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    from = Util.normalize_module(from)
    to = Util.normalize_module(to)

    if from == to, do: raise(ArgumentError, "#{inspect(from)} cannot target to self!")

    _new_from = nodes[from] || raise(ArgumentError, "#{inspect(from)} is not defined!")
    _new_to = nodes[to] || raise(ArgumentError, "#{inspect(to)} is not defined!")

    transition = %__MODULE__{module: o, id: id, opts: opts, from: from, to: to}
    {Edge.new(from, to, label: {o, id}), transition}
  end

  @spec validate(edge_map()) :: edge_map()
  def validate(transitions) do
    if Enum.empty?(transitions), do: raise(ArgumentError, "Transition is empty!")

    for {_, %__MODULE__{module: module, id: id}} <- transitions, reduce: [] do
      ary ->
        o = {module, id}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    for {%Edge{v1: v1, v2: v2}, _} <- transitions, reduce: [] do
      ary ->
        o = {v1, v2}
        if o in ary, do: raise(ArgumentError, "Transition #{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    transitions
  end
end
