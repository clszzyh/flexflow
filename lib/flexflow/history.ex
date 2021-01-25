defmodule Flexflow.History do
  @moduledoc """
  History
  """

  @type event :: :process_init
  @type t :: %__MODULE__{name: Flexflow.name(), event: event()}

  @enforce_keys [:name, :event]
  defstruct @enforce_keys

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    _ref = :ets.new(__MODULE__, [:named_table, :bag, :public, write_concurrency: true])
    {:ok, nil}
  end

  @spec put(Flexflow.process_identity(), t()) :: true
  def put(id, history) do
    :ets.insert(__MODULE__, {id, history})
  end

  @spec get(Flexflow.process_identity()) :: [t()]
  def get(id) do
    :ets.lookup(__MODULE__, id) |> Keyword.values()
  end
end
