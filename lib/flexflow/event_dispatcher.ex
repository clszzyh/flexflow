defmodule Flexflow.EventDispatcher do
  @moduledoc """
  EventDispatcher
  """

  @type key :: term()
  @type entry :: term()
  @type listener :: {key, entry}
  @type listen_result :: :wait | :ok

  alias Flexflow.Process
  require Logger

  @doc """
  ## Examples

      iex> #{__MODULE__}.child_spec([:a, :b, :c])
      %{
        id: #{__MODULE__},
        start: {Registry, :start_link, [[keys: :duplicate, name: #{__MODULE__}]]},
        type: :supervisor
      }
  """
  def child_spec(_args) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  @spec init_register_all(Process.t()) :: Process.result()
  def init_register_all(%{__listeners__: listeners} = p) do
    listeners
    |> Enum.reduce_while(%{}, fn
      {{key, entry}, :ok}, map ->
        {:cont, Map.put(map, {key, entry}, :ok)}

      {{key, entry}, :wait}, map ->
        case register(key, entry) do
          {:ok, _pid} -> {:cont, Map.put(map, {key, entry}, :ok)}
          {:error, reason} -> {:halt, {:error, reason}}
        end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      map -> {:ok, %{p | __listeners__: map}}
    end
  end

  @spec process_register(Process.t(), listener) :: Process.result()
  def process_register(%Process{__listeners__: listeners} = p, {key, entry}) do
    if Map.has_key?(listeners, {key, entry}) do
      {:error, :duplicate_listener}
    else
      case register(key, entry) do
        {:ok, _pid} -> %{p | __listeners__: Map.put(listeners, {key, entry}, :ok)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec register(key(), entry()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(key, entry) do
    Registry.register(__MODULE__, key, entry)
  end

  def keys, do: Registry.keys(__MODULE__, self())
  def lookup(key), do: Registry.lookup(__MODULE__, key)

  def dispatch(key) do
    Registry.dispatch(__MODULE__, key, fn entries ->
      for k <- entries, do: apply_dispatch(k)
    end)
  end

  # send(pid, {:broadcast, "world"})
  defp apply_dispatch({pid, {module, function}}) do
    apply(module, function, [pid])
  catch
    kind, reason ->
      formatted = Exception.format(kind, reason, __STACKTRACE__)
      Logger.error("Registry.dispatch/3 failed with #{formatted}")
  end
end
