for i <- 1..10 do
  defmodule String.to_atom("Elixir.E#{i}") do
    @moduledoc false
    use Flexflow.Event
    @impl true
    def name, do: unquote(String.to_atom("e#{i}"))
  end

  defmodule String.to_atom("Elixir.T#{i}") do
    @moduledoc false
    use Flexflow.Transition
    @impl true
    def name, do: unquote(String.to_atom("t#{i}"))
  end
end

defmodule P1 do
  @moduledoc false
  use Flexflow.Process

  defevent E1, foo: :bar
  defevent E2
  defevent E3
  deftransition T1, {E1, E2}
end

defmodule P2 do
  @moduledoc false
  use Flexflow.Process

  defevent E1
  defevent E2
  defevent E3
  defevent {E2, :two}
  deftransition T1, {E1, E2}
  deftransition T2, {E2, E3}
end
