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
    assert P1.new(%{foo: :bar}).args == %{foo: :bar}
    assert P1.new().name == :p1
    assert P1.new().opts == [hello: %{foo: :zzzz}]
    assert P1.new().graph.__struct__ == Graph
    assert P1.new().module == P1

    e1 = %N{module: N1, name: :n1, opts: [foo: %{aaa: :bbb}]}
    e2 = %N{module: N2, name: :n2}
    e3 = %N{module: N3, name: :n3}

    t1 = %T{module: T1, name: :t1, opts: [foo: :baz], from: {N1, :n1}, to: {N2, :n2}}
    t2 = %T{module: T2, name: :t2, from: {N2, :n2}, to: {N3, :n3}}

    assert P1.new().graph ==
             Graph.new()
             |> Graph.add_vertices([{N1, :n1}, {N2, :n2}, {N3, :n3}])
             |> Graph.add_edges([
               Graph.Edge.new({N1, :n1}, {N2, :n2}, label: {T1, :t1}),
               Graph.Edge.new({N2, :n2}, {N3, :n3}, label: {T2, :t2})
             ])

    assert P1.new().nodes == %{{N1, :n1} => e1, {N2, :n2} => e2, {N3, :n3} => e3}
    assert P1.new().transitions == %{{T1, :t1} => t1, {T2, :t2} => t2}

    assert Enum.count(P1.new().graph.vertices) == 3
  end

  test "init" do
    {:ok, p} = Flexflow.Process.start(P1)
    assert p.state == :initial
    assert p.nodes[{N1, :n1}].state == :initial
    assert p.transitions[{T1, :t1}].state == :initial
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
        deftransition T2, {N1, N2}
      end,
      "Transition {{N1, nil}, {N2, nil}} is defined twice!",
      quote do
        defnode(N1)
        defnode(N2)
        defnode(N3)
        deftransition T1, {N1, N2}
        deftransition T1, {N2, N3}
      end,
      "Transition {T1, nil} is defined twice!"
    ]

    for {ast, msg} <- Enum.chunk_every(data, 2) do
      assert_raise ArgumentError, msg, fn ->
        Module.create(
          P,
          [
            quote do
              use Flexflow.Process
              @impl true
              def name, do: :p
            end,
            ast
          ],
          Macro.Env.location(__ENV__)
        )
      end
    end
  end
end
