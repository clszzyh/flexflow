defmodule Flexflow.Util do
  @moduledoc false

  def local_modules do
    {:ok, [_ | _] = modules} = :application.get_key(:flexflow, :modules)
    modules
  end

  def modules do
    case :code.get_mode() do
      :interactive -> (:erlang.loaded() ++ get_modules_from_applications()) |> Enum.uniq()
      _ -> :erlang.loaded()
    end
  end

  def get_modules_from_applications do
    for [app] <- loaded_applications(),
        {:ok, modules} = :application.get_key(app, :modules),
        module <- modules do
      module
    end
  end

  # https://github.com/elixir-lang/elixir/blob/master/lib/iex/lib/iex/autocomplete.ex#L445-L452
  defp loaded_applications do
    # If we invoke :application.loaded_applications/0,
    # it can error if we don't call safe_fixtable before.
    # Since in both cases we are reaching over the
    # application controller internals, we choose to match
    # for performance.
    :ets.match(:ac_tab, {{:loaded, :"$1"}, :_})
  end

  def local_behaviour?(module) do
    module
    |> Code.ensure_compiled()
    |> case do
      {:module, _} ->
        module
        |> main_behaviour
        |> to_string
        |> case do
          "Elixir.Flexflow." <> _ -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def defined?(module) when is_atom(module) do
    module
    |> Code.ensure_compiled()
    |> case do
      {:module, _} -> true
      _ -> false
    end
  end

  def main_behaviour(module) do
    module
    |> defined?()
    |> case do
      false ->
        nil

      true ->
        module.module_info(:attributes)
        |> List.wrap()
        |> Keyword.get(:behaviour)
        |> List.wrap()
        |> List.first()
    end
  end
end
