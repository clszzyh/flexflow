defmodule Flexflow.Tracker do
  @moduledoc false

  @trackers [Flexflow.ProcessTracker, Flexflow.StateTracker, Flexflow.EventTracker]

  def impls do
    for t <- @trackers, into: %{} do
      {:consolidated, modules} = t.__protocol__(:impls)
      {t, Map.new(modules, &{&1, &1.name()})}
    end
  end

  def ensure_unique do
    for {kind, modules} <- impls(), {module, name} <- modules, reduce: %{} do
      map ->
        exist = Map.get(map, {kind, name})

        if exist do
          raise(ArgumentError, "Already exists #{name}: `#{module}` and `#{exist}`")
        end

        Map.put(map, {kind, name}, module)
    end

    :ok
  end
end

defprotocol Flexflow.ProcessTracker do
  def ping(o)
end

defprotocol Flexflow.StateTracker do
  def ping(o)
end

defprotocol Flexflow.EventTracker do
  def ping(o)
end
