defmodule Flexflow.Event do
  @moduledoc """
  Event
  """

  alias Flexflow.Util

  @type t :: %__MODULE__{
          module: module(),
          id: Flexflow.id(),
          opts: keyword()
        }

  @enforce_keys [:id, :module]
  defstruct @enforce_keys ++ [opts: []]

  @callback name :: Flexflow.name()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  @spec define({Flexflow.event_key(), keyword()}) :: t()
  def define({o, opts}) when is_atom(o), do: define({Util.normalize_module(o), opts})

  def define({{o, id}, opts}) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    %__MODULE__{module: o, id: id, opts: opts}
  end

  @spec validate([t()]) :: [t()]
  def validate(events) do
    if Enum.empty?(events), do: raise(ArgumentError, "Event is empty!")

    for %__MODULE__{module: module, id: id} <- events, reduce: [] do
      ary ->
        o = {module, id}
        if o in ary, do: raise(ArgumentError, "Event #{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    events
  end
end
