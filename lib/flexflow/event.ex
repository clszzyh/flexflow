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

  def define({o, opts}) when is_atom(o), do: define({Util.normalize_module(o), opts})

  def define({{o, id}, _opts}) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    {o, id}
  end

  def validate(events) do
    if Enum.empty?(events), do: raise(ArgumentError, "Event is empty!")

    for o <- events, reduce: [] do
      ary ->
        if o in ary, do: raise(ArgumentError, "#{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    events
  end
end
