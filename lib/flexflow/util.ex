defmodule Flexflow.Util do
  @moduledoc false

  alias Flexflow.Event
  alias Flexflow.Events.Basic
  alias Flexflow.Process
  alias Flexflow.State
  alias Flexflow.States.Bypass

  @local_behaviours [Process, Event, State]

  defp module_atom?(o) when is_atom(o), do: match?("Elixir." <> _, to_string(o))

  @spec normalize_module(
          Flexflow.state_type_or_module()
          | {Flexflow.state_type_or_module(), Flexflow.state_type_or_module(),
             Flexflow.state_type_or_module()},
          [State.t()]
        ) ::
          Flexflow.state_type()
  def normalize_module(o, states \\ [])

  def normalize_module({o, name}, _states) when is_atom(o), do: {o, name}
  def normalize_module({{o, name}, _from, _to}, _states) when is_atom(o), do: {o, name}

  def normalize_module(o, states) when is_atom(o) do
    if module_atom?(o) do
      _ = Code.ensure_loaded(o)

      if function_exported?(o, :name, 0) do
        {o, o.name()}
      else
        raise ArgumentError, "`#{o}` should have a `name/0` function"
      end
    else
      case Enum.find(states, fn e -> e.name == o end) do
        nil -> {Bypass, o}
        e -> {e.module, o}
      end
    end
  end

  def normalize_module({o, {_, from_name}, {_, to_name}}, _states) when is_atom(o) do
    if module_atom?(o) do
      {o, :"#{o.name()}_#{from_name}_#{to_name}"}
    else
      {Basic, o}
    end
  end

  def normalize_module({o, from, to}, states) when is_atom(o) and is_atom(from) do
    normalize_module({o, normalize_module(from, states), to}, states)
  end

  @spec random(non_neg_integer()) :: String.t()
  def random(length \\ 20) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @spec make_id :: Flexflow.id()
  def make_id do
    to_string(System.unique_integer([:positive]))
  end

  @doc """
  Get module name

  ## Examples

      iex> #{__MODULE__}.module_name(Foo.Bar.FooBar)
      :foo_bar
  """
  @spec module_name(atom()) :: Flexflow.name()
  def module_name(module) do
    module
    |> Macro.to_string()
    |> String.split(".")
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()
  end

  @spec modules :: [module()]
  def modules do
    case :code.get_mode() do
      :interactive -> (:erlang.loaded() ++ get_modules_from_applications()) |> Enum.uniq()
      _ -> :erlang.loaded()
    end
  end

  defp get_modules_from_applications do
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

  @spec implement_modules([module()]) :: [module()]
  def implement_modules(behaviours \\ @local_behaviours) do
    for module <- modules(), local_behaviour(module) in behaviours, do: module
  end

  @spec defined?(module()) :: boolean()
  def defined?(module) when is_atom(module) do
    case Code.ensure_compiled(module) do
      {:module, _} -> true
      _ -> false
    end
  end

  @spec local_behaviour(module()) :: module() | nil
  def local_behaviour(module) do
    if defined?(module) do
      module.module_info(:attributes)
      |> List.wrap()
      |> Keyword.get(:behaviour)
      |> List.wrap()
      |> Enum.find(&(&1 in @local_behaviours))
    end
  end
end
