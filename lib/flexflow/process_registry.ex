defmodule Flexflow.ProcessRegistry do
  @moduledoc """

  ## Examples

      iex> defmodule DemoRegistry do
      ...>   use #{__MODULE__}
      ...> end
      ...> match?({:via, Registry, {#{__MODULE__}, {DemoRegistry, :abc}}}, DemoRegistry.via_tuple(:abc))
      true

  """

  defmacro __using__(_) do
    quote do
      def via_tuple(worker_id) do
        unquote(__MODULE__).via_tuple({__MODULE__, worker_id})
      end

      def pid(worker_id) do
        unquote(__MODULE__).pid({__MODULE__, worker_id})
      end
    end
  end

  @doc """
  ## Examples

      iex> #{__MODULE__}.child_spec([:a, :b, :c])
      %{
        id: #{__MODULE__},
        start: {Registry, :start_link, [[keys: :unique, name: #{__MODULE__}]]},
        type: :supervisor
      }
  """
  def child_spec(_args) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  # Registry.lookup(__MODULE__, {GenStarter.DatabaseWorker, 1})

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def lookup(key), do: Registry.lookup(__MODULE__, key)
  def count, do: Registry.count(__MODULE__)

  def pid(key) do
    key
    |> lookup
    |> case do
      [{pid, _}] when is_pid(pid) -> pid
      _ -> nil
    end
  end

  @list_query [{{{:"$1", :"$2"}, :"$3", :_}, [], [%{module: :"$1", name: :"$2", pid: :"$3"}]}]

  def list, do: Registry.select(__MODULE__, @list_query)
end
