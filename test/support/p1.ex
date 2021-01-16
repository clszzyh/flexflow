defmodule E1 do
  @moduledoc false
  use Flexflow.Event
  @impl true
  def name, do: :e1
end

defmodule E2 do
  @moduledoc false
  use Flexflow.Event
  @impl true
  def name, do: :e2
end

defmodule T1 do
  @moduledoc false
  use Flexflow.Transition
  @impl true
  def name, do: :t1
end

defmodule P1 do
  @moduledoc false
  use Flexflow.Process
  defevent E1
  defevent E2
  deftransition T1, {E1, E2}
end
