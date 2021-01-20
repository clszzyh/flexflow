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
  def name, do: "p1_new"

  defstart N1, foo: %{aaa: :bbb}
  node N2
  transition T1, N1 ~> N2, foo: :baz

  node N3
  node N4
  defend N5
  node N6
  transition T2, N2 ~> N3
  transition {T2, "1"}, N2 ~> N4
  transition {T2, "2"}, N2 ~> N5
  transition {T2, "3"}, N2 ~> N6
  transition {T2, "4"}, N4 ~> N1
end
