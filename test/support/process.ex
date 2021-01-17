for i <- 1..10 do
  defmodule String.to_atom("Elixir.N#{i}") do
    @moduledoc false
    use Flexflow.Node
    @impl true
    def name, do: unquote(String.to_atom("n#{i}"))
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
  use Flexflow.Process, hello: %{foo: :zzzz}

  @impl true
  def name, do: :p1

  defnode(N1, foo: %{aaa: :bbb})
  defnode(N2)
  defnode(N3)
  deftransition T1, {N1, N2}, foo: :baz
  deftransition T2, {N2, N3}
end
