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
    n5_s = {N5, "n5"}
    n6_s = {N6, "n6"}

    n1 = N.new({n1_s, foo: %{aaa: :bbb}, kind: :start})
    n2 = N.new({n2_s, []})
    n3 = N.new({n3_s, []})
    n4 = N.new({n4_s, []})
    n5 = N.new({n5_s, kind: :end})
    n6 = N.new({n6_s, []})

    t1 = %T{module: T1, name: "t1_by_n1", opts: [foo: :baz], from: n1_s, to: n2_s}
    t2 = %T{module: T2, name: "t2_by_n2", from: n2_s, to: n3_s}
    t3 = %T{module: T2, name: "1", from: n2_s, to: n4_s}
    t4 = %T{module: T2, name: "2", from: n2_s, to: n5_s}
    t5 = %T{module: T2, name: "3", from: n2_s, to: n6_s}
    t6 = %T{module: T2, name: "4", from: n4_s, to: n1_s}

    t1_s = {T1, "t1_by_n1"}
    t2_s = {T2, "t2_by_n2"}
    t3_s = {T2, "1"}
    t4_s = {T2, "2"}
    t5_s = {T2, "3"}
    t6_s = {T2, "4"}

    assert P1.new().__identities__ == [
             node: n1_s,
             node: n2_s,
             transition: t1_s,
             node: n3_s,
             node: n4_s,
             node: n5_s,
             node: n6_s,
             transition: t2_s,
             transition: t3_s,
             transition: t4_s,
             transition: t5_s,
             transition: t6_s
           ]

    assert P1.new().graph ==
             Graph.new()
             |> Graph.add_vertices([n1_s, n2_s, n3_s, n4_s, n5_s, n6_s])
             |> Graph.add_edges([
               Graph.Edge.new(n1_s, n2_s, label: t1_s),
               Graph.Edge.new(n2_s, n3_s, label: t2_s),
               Graph.Edge.new(n2_s, n4_s, label: t3_s),
               Graph.Edge.new(n2_s, n5_s, label: t4_s),
               Graph.Edge.new(n2_s, n6_s, label: t5_s),
               Graph.Edge.new(n4_s, n1_s, label: t6_s)
             ])

    assert P1.new().nodes == %{
             n1_s => n1,
             n2_s => n2,
             n3_s => n3,
             n4_s => n4,
             n5_s => n5,
             n6_s => n6
           }

    assert P1.new().transitions == %{
             t1_s => t1,
             t2_s => t2,
             t3_s => t3,
             t4_s => t4,
             t5_s => t5,
             t6_s => t6
           }

    assert Enum.count(P1.new().graph.vertices) == 6

    assert Map.new(P1.new().__path__) == %{
             n1_s => %{n2_s => t1_s},
             n2_s => %{n5_s => t4_s, n3_s => t2_s, n4_s => t3_s, n6_s => t5_s},
             n3_s => %{},
             n4_s => %{n1_s => t6_s},
             n5_s => %{},
             n6_s => %{}
           }
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
        node(N1)
      end,
      "Transition is empty",
      quote do
        node(N0)
      end,
      "N0 should implement Elixir.Flexflow.Node",
      quote do
        node(N1)
        node(N2)
        node(N1)
        transition(T1, N1 ~> N2)
      end,
      "Node {N1, nil} is defined twice",
      quote do
        node(N1)
        transition(T1, N1 ~> N4)
      end,
      "{N4, nil} is not defined",
      quote do
        node(N1)
        node(N2)
        transition(T1, N1 ~> N2)
        transition(T2, N1 ~> N2)
      end,
      "Transition {{N1, nil}, {N2, nil}} is defined twice",
      quote do
        node(N1)
        node(N2)
        node(N3)
        transition(T1, N1 ~> N2)
        transition(T1, N2 ~> N3)
      end,
      "Transition {T1, nil} is defined twice",
      quote do
        node(N1)
        node(N2)
        transition(T1, N1 ~> N2)
      end,
      "Need a start node",
      quote do
        defstart(N1)
        defstart(N2)
        transition(T1, N1 ~> N2)
      end,
      "Only need one start node",
      quote do
        defstart(N1)
        node(N2)
        transition(T1, N1 ~> N2)
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
