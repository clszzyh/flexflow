defmodule Flexflow.HookDispatcher do
  @moduledoc """
  HookDispatcher
  """

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

  def register(key, entry) do
    Registry.register(__MODULE__, key, entry)
  end

  def dispatch(key) do
    Registry.dispatch(__MODULE__, key, fn entries ->
      for k <- entries, do: apply_dispatch(k)
    end)
  end

  defp apply_dispatch({pid, {module, function}}) do
    apply(module, function, [pid])
  catch
    kind, reason ->
      formatted = Exception.format(kind, reason, __STACKTRACE__)
      Logger.error("Registry.dispatch/3 failed with #{formatted}")
  end
end
