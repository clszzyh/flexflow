defmodule Flexflow.Node do
  @moduledoc """
  Node
  """

  alias Flexflow.Context
  alias Flexflow.Process
  alias Flexflow.Util

  @states [:created, :initial, :ready, :completed]

  @typedoc """
  Node state

  #{inspect(@states)}
  """
  @opaque state :: unquote(Enum.reduce(@states, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          module: module(),
          state: state(),
          name: Flexflow.name(),
          context: Context.t(),
          opts: Flexflow.node_opts()
        }

  @enforce_keys [:name, :module]
  defstruct @enforce_keys ++ [state: :created, opts: [], context: Context.new()]

  @doc "Module name"
  @callback name :: Flexflow.name()

  @doc "Invoked when process is started"
  @callback init(t(), Process.t()) :: {:ok, t()}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc """
        See `#{unquote(__MODULE__)}`
        """
      end

      @impl true
      def name, do: Flexflow.Util.module_name(__MODULE__)

      @impl true
      def init(o, _), do: {:ok, o}

      defoverridable unquote(__MODULE__)
    end
  end

  @spec new({Flexflow.key(), Flexflow.node_opts()}) :: t()
  def new({o, opts}) when is_atom(o), do: new({Util.normalize_module(o), opts})

  def new({{o, name}, opts}) do
    unless Util.local_behaviour(o) == __MODULE__ do
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
