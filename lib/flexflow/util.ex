defmodule Flexflow.Util do
  @moduledoc false

  def local_behaviour?(module) do
    module
    |> main_behaviour
    |> to_string
    |> case do
      "Elixir.Flexflow." <> _ -> true
      _ -> false
    end
  end

  def main_behaviour(module) do
    module.module_info(:attributes)
    |> List.wrap()
    |> Keyword.get(:behaviour)
    |> List.wrap()
    |> List.first()
  end
end
