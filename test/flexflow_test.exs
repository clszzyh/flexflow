defmodule FlexflowTest do
  use ExUnit.Case, async: true
  doctest Flexflow

  @moduletag capture_log: true

  alias Flexflow.Node, as: N
  alias Flexflow.Transition, as: T

  test "version" do
    assert Flexflow.version()
  end

  test "p1" do
    assert P1.module_info()
    assert P1.new("p1", %{foo: :bar}).args == %{foo: :bar}
    assert P1.new("p1", %{foo: :bar}).id == "p1"
    assert P1.new().name == "p1_new"
    assert P1.new().opts == [hello: %{foo: :zzzz}]
    assert P1.new().graph.__struct__ == Graph
    assert P1.new().module == P1

    n1_s = {N1, "n1"}
    n2_s = {N2, "n2"}
    n3_s = {N3, "n3"}
    n4_s = {N4, "n4"}

    t1 = %T{module: T1, name: "t1_by_n1", opts: [foo: :baz], from: n1_s, to: n2_s}
    t2 = %T{module: T2, name: "t2_by_n2", from: n2_s, to: n3_s}
    t3 = %T{module: T2, name: "1", from: n2_s, to: n4_s}

    n1 = N.new({n1_s, foo: %{aaa: :bbb}, kind: :start})
    n2 = N.new({n2_s, []})
    n3 = N.new({n3_s, []})
    n4 = N.new({n4_s, kind: :end})

    n1 = %{n1 | __out_edges__: [{{T1, "t1_by_n1"}, {N2, "n2"}}]}

    n2 = %{
      n2
      | __in_edges__: [{{T1, "t1_by_n1"}, {N1, "n1"}}],
        __out_edges__: [{{T2, "t2_by_n2"}, {N3, "n3"}}, {{T2, "1"}, {N4, "n4"}}]
    }

    n3 = %{n3 | __in_edges__: [{{T2, "t2_by_n2"}, {N2, "n2"}}]}
    n4 = %{n4 | __in_edges__: [{{T2, "1"}, {N2, "n2"}}]}

    t1_s = {T1, "t1_by_n1"}
    t2_s = {T2, "t2_by_n2"}
    t3_s = {T2, "1"}

    assert P1.new().__identities__ == [
             node: n1_s,
             node: n2_s,
             transition: t1_s,
             node: n3_s,
             node: n4_s,
             transition: t2_s,
             transition: t3_s
           ]

    assert P1.new().graph ==
             Graph.new()
             |> Graph.add_vertices([n1_s, n2_s, n3_s, n4_s])
             |> Graph.add_edges([
               Graph.Edge.new(n1_s, n2_s, label: t1_s),
               Graph.Edge.new(n2_s, n3_s, label: t2_s),
               Graph.Edge.new(n2_s, n4_s, label: t3_s)
             ])

    assert P1.new().nodes == %{n1_s => n1, n2_s => n2, n3_s => n3, n4_s => n4}
    assert P1.new().transitions == %{t1_s => t1, t2_s => t2, t3_s => t3}

    assert P1.new().start_node == n1_s
    assert Enum.count(P1.new().graph.vertices) == 4
  end

  test "init" do
    {:ok, p} = Flexflow.Process.start(P1, "p1")
    assert p.state == :active
    assert p.id == "p1"
    assert p.nodes[{N1, "n1"}].state == :initial
    assert p.transitions[{T1, "t1_by_n1"}].state == :initial
    assert p.transitions[{T1, "t1_by_n1"}]
  end

  test "process compile raise" do
    data = [
      quote do
      end,
      "Node is empty",
      quote do
        intermediate_node N1
      end,
      "Transition is empty",
      quote do
        intermediate_node N0
      end,
      "N0 should implement Elixir.Flexflow.Node",
      quote do
        intermediate_node N1
        intermediate_node N2
        intermediate_node N1
        transition T1, N1 ~> N2
      end,
      "Node {N1, nil} is defined twice",
      quote do
        intermediate_node N1
        transition T1, N1 ~> N4
      end,
      "{N4, nil} is not defined",
      quote do
        intermediate_node N1
        intermediate_node N2
        transition T1, N1 ~> N2
        transition T2, N1 ~> N2
      end,
      "Transition {{N1, nil}, {N2, nil}} is defined twice",
      quote do
        intermediate_node N1
        intermediate_node N2
        intermediate_node N3
        transition T1, N1 ~> N2
        transition T1, N2 ~> N3
      end,
      "Transition {T1, nil} is defined twice",
      quote do
        intermediate_node N1
        intermediate_node N2
        transition T1, N1 ~> N2
      end,
      "Need a start node",
      quote do
        start_node N1
        start_node N2
        transition T1, N1 ~> N2
      end,
      "Only need one start node",
      quote do
        start_node N1
        intermediate_node N2
        transition T1, N1 ~> N2
      end,
      "Need one or more end node"
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
