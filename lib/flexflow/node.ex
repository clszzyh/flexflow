defmodule Flexflow.Node do
  @moduledoc """
  Node
  """

  alias Flexflow.Context
  alias Flexflow.Process
  alias Flexflow.Util

  @type t :: %__MODULE__{
          module: module(),
          name: Flexflow.name(),
          context: Context.t(),
          opts: keyword()
        }

  @enforce_keys [:name, :module]
  defstruct @enforce_keys ++ [opts: [], context: Context.new()]

  @callback name :: Flexflow.name()
  @callback init(t(), Process.t()) :: {:ok, t()}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl true
      def init(o, _), do: {:ok, o}

      defoverridable unquote(__MODULE__)
    end
  end

  @spec define({Flexflow.key(), keyword()}) :: t()
  def define({o, opts}) when is_atom(o), do: define({Util.normalize_module(o), opts})

  def define({{o, name}, opts}) do
    unless Util.main_behaviour(o) == __MODULE__ do
      raise ArgumentError, "#{inspect(o)} should implement #{__MODULE__}"
    end

    %__MODULE__{module: o, name: name, opts: opts}
  end

  @spec validate([t()]) :: [t()]
  def validate(nodes) do
    if Enum.empty?(nodes), do: raise(ArgumentError, "Node is empty!")

    for %__MODULE__{module: module, name: name} <- nodes, reduce: [] do
      ary ->
        o = {module, name}
        if o in ary, do: raise(ArgumentError, "Node #{inspect(o)} is defined twice!")
        ary ++ [o]
    end

    nodes
  end
end
