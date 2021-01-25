defmodule Flexflow.Util do
  @moduledoc false

  alias Flexflow.Event
  alias Flexflow.Events.Bypass
  alias Flexflow.Gateway
  alias Flexflow.Gateways.Pass
  alias Flexflow.Process

  @local_behaviours [Process, Gateway, Event]

  @spec normalize_module(
          Flexflow.key()
          | String.t()
          | {Flexflow.key(), Flexflow.key(), Flexflow.key()},
          [Event.t()]
        ) ::
          Flexflow.key_normalize()
  def normalize_module(o, events \\ [])

  def normalize_module({o, _from, _to}, _events) when is_binary(o), do: {Pass, o}

  def normalize_module({o, from, _to}, events) when is_atom(o) do
    {_, from_name} = normalize_module(from, events)
    {o, o.name() <> "_" <> from_name}
  end

  def normalize_module(o, [_ | _] = events) when is_binary(o) do
    events
    |> Enum.find(fn %Event{name: name} -> name == o end)
    |> case do
      %Event{module: module, name: name} -> {module, name}
      _ -> raise ArgumentError, "Could not find module `#{o}`"
    end
  end

  def normalize_module(o, []) when is_binary(o), do: {Bypass, o}

  def normalize_module(o, _) when is_atom(o) do
    if function_exported?(o, :name, 0) do
      {o, o.name()}
    else
      raise ArgumentError, "`#{o}` should have a `name/0` function"
    end
  end

  def normalize_module({{o, name}, _from, _to}, _) when is_atom(o) and is_binary(name),
    do: {o, name}

  def normalize_module({o, name}, _) when is_atom(o) and is_binary(name), do: {o, name}

  @spec make_id :: Flexflow.id()
  def make_id do
    to_string(System.unique_integer([:positive]))
  end

  @doc """
  Get module name

  ## Examples

      iex> #{__MODULE__}.module_name(Foo.Bar.FooBar)
      "foo_bar"
  """

  @spec module_name(atom()) :: String.t()
  def module_name(module) do
    module
    |> to_string
    |> String.trim_leading("Elixir.")
    |> String.split(".")
    |> List.last()
    |> Macro.underscore()
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
    module
    |> Code.ensure_compiled()
    |> case do
      {:module, _} -> true
      _ -> false
    end
  end

  @spec local_behaviour(module()) :: module() | nil
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
