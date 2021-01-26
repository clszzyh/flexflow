defmodule Flexflow.EventDispatcher do
  @moduledoc """
  EventDispatcher
  """

  @type key :: term()
  @type entry :: term()
  @type listener :: {key, entry}

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

  @spec init_register_all([listener()]) :: :ok | {:error, term()}
  def init_register_all([]), do: :ok

  def init_register_all([{key, entry} | rest]) do
    case register(key, entry) do
      {:ok, _pid} -> init_register_all(rest)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec register(key(), entry()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(key, entry) do
    Registry.register(__MODULE__, key, entry)
  end

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
