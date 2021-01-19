defmodule Flexflow.Util do
  @moduledoc false

  @local_behaviours [Flexflow.Process, Flexflow.Transition, Flexflow.Node]

  @spec normalize_module(Flexflow.key()) :: Flexflow.key_normalize()
  def normalize_module({o, id}) when is_atom(o), do: {o, id}
  def normalize_module(o) when is_atom(o), do: {o, o.name()}

  @spec make_id :: Flexflow.id()
  def make_id do
    to_string(System.unique_integer([:positive]))
  end

  @doc """
  Get module name

  ## Examples

      iex> #{__MODULE__}.module_name(Foo.Bar.FooBar)
      :foo_bar_foo_bar
  """

  @spec module_name(atom()) :: atom()
  def module_name(module) do
    module
    |> to_string
    |> String.trim_leading("Elixir.")
    |> String.replace(".", "")
    |> Macro.underscore()
    |> String.to_atom()
  end

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

  def implement_modules(behaviours \\ @local_behaviours) do
    for module <- modules(), local_behaviour?(module, behaviours), do: module
  end

  def local_behaviour?(module, behaviours \\ @local_behaviours) do
    module
    |> Code.ensure_compiled()
    |> case do
      {:module, _} -> local_behaviour(module) in behaviours
      _ -> false
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

  def local_behaviour(module) do
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
        |> Enum.find(&(&1 in @local_behaviours))
    end
  end
end
