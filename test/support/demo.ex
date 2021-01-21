for i <- 1..10 do
  defmodule String.to_atom("Elixir.N#{i}") do
    @moduledoc false
    use Flexflow.Node
  end

  defmodule String.to_atom("Elixir.T#{i}") do
    @moduledoc false
    use Flexflow.Transition
  end
end

defmodule P1 do
  @moduledoc false
  use Flexflow.Process, hello: %{foo: :zzzz}

  @impl true
  def name, do: "p1_new"

  start_node N1, foo: %{aaa: :bbb}
  intermediate_node N2

  transition T1, N1 ~> N2, foo: :baz

  intermediate_node N3, async: true
  end_node N4

  transition T2, N2 ~> N3, async: true
  transition {T2, "1"}, N2 ~> N4
end
