for i <- 1..10 do
  defmodule String.to_atom("Elixir.N#{i}") do
    @moduledoc false
    use Flexflow.Node
  end

  defmodule String.to_atom("Elixir.T#{i}") do
    @moduledoc false
    use Flexflow.Transition
    @impl true
    def handle_enter(_, _, _), do: :pass
  end
end

defmodule P1 do
  @moduledoc false
  use Flexflow.Process, hello: %{foo: :zzzz}

  @impl true
  def name, do: :p1_new

  defnode N1, foo: %{aaa: :bbb}
  defnode N2
  defnode N3
  defnode N4
  defnode N5
  defnode N6
  deftransition T1, {N1, N2}, foo: :baz
  deftransition T2, {N2, N3}
  deftransition {T2, 1}, {N2, N4}
  deftransition {T2, 2}, {N2, N5}
  deftransition {T2, 3}, {N2, N6}
  deftransition {T2, 4}, {N4, N1}
end
