defmodule Flexflow.History do
  @moduledoc """
  History
  """

  @events [:process_init, :process_loop]
  @stages [:start, :end]
  @type event :: unquote(Enum.reduce(@events, &{:|, [], [&1, &2]}))
  @type stage :: unquote(Enum.reduce(@stages, &{:|, [], [&1, &2]}))
  @type t :: %__MODULE__{
          name: Flexflow.name(),
          stage: stage,
          metadata: map,
          measurements: map,
          event: event(),
          time: integer
        }
  @type new_input :: t() | map() | event()

  @enforce_keys [:name, :event, :time, :stage]
  defstruct @enforce_keys ++ [measurements: %{}, metadata: %{}]

  @spec new(new_input) :: t()
  def new(event) when event in @events,
    do: %__MODULE__{name: :process, stage: :start, event: event, time: System.monotonic_time()}

  def new(%{} = map) do
    struct!(__MODULE__, Map.merge(map, %{name: :process, time: System.monotonic_time()}))
  end

  def new(%__MODULE__{} = his), do: his

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    _ref = :ets.new(__MODULE__, [:named_table, :bag, :public, write_concurrency: true])
    {:ok, nil}
  end

  @spec put(Flexflow.process_identity(), new_input()) :: :ok
  def put(id, history) do
    true = :ets.insert(__MODULE__, {id, new(history)})
    :ok
  end

  @spec ensure_new(Flexflow.process_identity()) :: {:ok, nil} | {:error, term()}
  def ensure_new(id) do
    if :ets.member(__MODULE__, id) do
      {:error, "Key exist"}
    else
      {:ok, id}
    end
  end

  @spec get(Flexflow.process_identity()) :: [t()]
  def get(id) do
    :ets.lookup(__MODULE__, id) |> Keyword.values()
  end
end
