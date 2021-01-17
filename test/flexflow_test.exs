defmodule FlexflowTest do
  use ExUnit.Case
  doctest Flexflow

  alias Flexflow.Node, as: N
  alias Flexflow.Transition, as: T

  test "version" do
    assert Flexflow.version()
  end

  test "p1" do
    assert P1.module_info()
    assert P1.new()
    assert P1.new(%{name: :foo}).name == :foo
    assert P1.new(name: :foo).name == :foo
    assert P1.new().graph.__struct__ == Graph
    assert P1.new().module == P1

    e1 = %N{module: N1, id: nil, opts: [foo: :bar]}
    e2 = %N{module: N2, id: nil}
    e3 = %N{module: N3, id: nil}

    t1 = %T{module: T1, opts: [foo: :baz], from: {N1, nil}, to: {N2, nil}}
    t2 = %T{module: T2, from: {N2, nil}, to: {N3, nil}}

    assert P1.new().graph ==
             Graph.new()
             |> Graph.add_vertices([{N1, nil}, {N2, nil}, {N3, nil}])
             |> Graph.add_edges([
               Graph.Edge.new({N1, nil}, {N2, nil}, label: t1),
               Graph.Edge.new({N2, nil}, {N3, nil}, label: t2)
             ])

    assert P1.new().nodes == %{{N1, nil} => e1, {N2, nil} => e2, {N3, nil} => e3}

    assert Enum.count(P1.new().graph.vertices) == 3
  end

  test "process compile raise" do
    data = [
      quote do
      end,
      "Node is empty!",
      quote do
        defnode(N1)
      end,
      "Transition is empty!",
      quote do
        defnode(N0)
      end,
      "N0 should implement Elixir.Flexflow.Node",
      quote do
        defnode(N1)
        defnode(N2)
        defnode(N1)
        deftransition T1, {N1, N2}
      end,
      "Node {N1, nil} is defined twice!",
      quote do
        defnode(N1)
        deftransition T1, {N1, N4}
      end,
      "{N4, nil} is not defined!",
      quote do
        defnode(N1)
        deftransition T1, {N1, N1}
      end,
      "{N1, nil} cannot target to self!",
      quote do
        defnode(N1)
        defnode(N2)
        deftransition T1, {N1, N2}
        deftransition T1, {N1, N2}
      end,
      "Transition {{N1, nil}, {N2, nil}} is defined twice!"
    ]

    for {ast, msg} <- Enum.chunk_every(data, 2) do
      assert_raise ArgumentError, msg, fn ->
        Module.create(
          P,
          [
            quote do
              use Flexflow.Process
            end,
            ast
          ],
          Macro.Env.location(__ENV__)
        )
      end
    end
  end
end
