defmodule Flexflow.Tracker do
  @moduledoc false

  @trackers [Flexflow.ProcessTracker, Flexflow.StateTracker, Flexflow.EventTracker]

  def impls do
    for t <- @trackers, into: %{} do
      {:consolidated, modules} = t.__protocol__(:impls)

      {t, modules}
    end
  end

  def ensure_unique do
    for {_, modules} <- impls() do
      for module <- modules, reduce: %{} do
        map ->
          exist = Map.get(map, module.name())

          if exist do
            raise(ArgumentError, "Already exists #{module.name()}: `#{module}` and `#{exist}`")
          end

          Map.put(map, module.name(), module)
      end
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
