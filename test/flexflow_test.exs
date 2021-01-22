defmodule FlexflowTest do
  use ExUnit.Case, async: true
  doctest Flexflow

  @moduletag capture_log: true
  @moduletag :basic

  alias Flexflow.Event, as: N
  alias Flexflow.Transition, as: T

  setup_all do
    :ok = Application.ensure_started(:flexflow)
    []
  end

  test "version" do
    assert Flexflow.version()
  end

  test "p1" do
    assert P1.module_info()
    assert P1.new("p1", %{foo: :bar}).__args__ == %{foo: :bar}
    assert P1.new("p1", %{foo: :bar}).id == "p1"
    assert P1.new().name == "p1_new"
    assert P1.new().__opts__ == [hello: %{foo: :zzzz}]
    assert P1.new().module == P1

    n1_s = {N1, "n1"}
    n2_s = {N2, "n2"}
    n3_s = {N3, "n3"}
    n4_s = {N4, "n4"}

    t1 = %T{module: T1, name: "t1_by_n1", __opts__: [foo: :baz], from: n1_s, to: n2_s}

    t2 = %T{
      module: T2,
      name: "t2_by_n2",
      __graphviz__: [style: "bold", color: "red"],
      from: n2_s,
      to: n3_s,
      __opts__: [async: true]
    }

    t3 = %T{module: T2, name: "1", from: n2_s, to: n4_s}

    n1 = N.new({n1_s, foo: %{aaa: :bbb}, kind: :start})
    n2 = N.new({n2_s, []})
    n3 = N.new({n3_s, async: true})
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
             event: n1_s,
             event: n2_s,
             transition: t1_s,
             event: n3_s,
             event: n4_s,
             transition: t2_s,
             transition: t3_s
           ]

    assert P1.new().events == %{n1_s => n1, n2_s => n2, n3_s => n3, n4_s => n4}
    assert P1.new().transitions == %{t1_s => t1, t2_s => t2, t3_s => t3}
  end

  test "p2" do
    {:ok, p} = Flexflow.Process.new(P2, "p2")
    assert p.state == :active
  end

  test "init" do
    {:ok, p} = Flexflow.Process.new(P1, "p1")
    assert p.state == :active
    assert p.id == "p1"
    assert p.events[{N1, "n1"}].state == :ready
    assert p.events[{N2, "n2"}].state == :initial
    assert p.transitions[{T1, "t1_by_n1"}].state == :initial
    assert p.transitions[{T1, "t1_by_n1"}]
  end

  test "process compile raise" do
    data = [
      quote do
      end,
      {0, "Event is empty"},
      quote do
        event N1, kind: :start
        event N2, kind: :end
      end,
      {1, "Transition is empty"},
      quote do
        event N0
      end,
      {2, "`Elixir.N0` should have a `name/0` function"},
      quote do
        event N1
        event N2
        event N1
        transition T1, N1 ~> N2
      end,
      {3, "Event `n1` is defined twice"},
      quote do
        event N1, kind: :start
        event N2, kind: :end
        transition T1, "n1" ~> N4
      end,
      {4, "`{N4, \"n4\"}` is not defined"},
      quote do
        event N1, kind: :start
        event N2, kind: :end
        transition T1, "n1" ~> "n2"
        transition T2, "n1" ~> "n2"
      end,
      {5, "Transition `{{N1, \"n1\"}, {N2, \"n2\"}}` is defined twice"},
      quote do
        event Flexflow.Events.Start
        event Flexflow.Events.End
        event N1
        transition {T1, "t"}, Flexflow.Events.Start ~> Flexflow.Events.End
        transition {T1, "t"}, N1 ~> Flexflow.Events.End
      end,
      {6, "Transition `{T1, \"t\"}` is defined twice"},
      quote do
        event N1
        event N2
        transition T1, N1 ~> N2
      end,
      {7, "Need a start event"},
      quote do
        event N1, kind: :start
        event N2, kind: :start
        transition T1, N1 ~> N2
      end,
      {8, "Multiple start event found"},
      quote do
        event N1, kind: :start
        event N2
        transition T1, N1 ~> N2
      end,
      {9, "Need one or more end event"},
      quote do
        event N1, kind: :start
        event N2
        event N3, kind: :end
        transition T1, N1 ~> N2
      end,
      {10, "In edges of `{N3, \"n3\"}` is empty"},
      quote do
        event N1, kind: :start
        event N2
        event N3, kind: :end
        transition T1, N2 ~> N3
      end,
      {11, "Out edges of `{N1, \"n1\"}` is empty"},
      quote do
        event N1, kind: :start
        event N2
        event N3, kind: :end
        transition T1, N1 ~> N3
      end,
      {12, "`{N2, \"n2\"}` is isolated"},
      quote do
        event N1, kind: :start
        event N3, kind: :end
        transition T1, "n" ~> N3
      end,
      {13, "Could not find module `n`"},
      quote do
        event {N1, "n"}, kind: :start
        event {N2, "n"}
        event N3, kind: :end
        transition T1, "n" ~> N3
      end,
      {14, "Event `n` is defined twice"}
    ]

    for [ast, {index, msg}] <- Enum.chunk_every(data, 2) do
      assert_raise ArgumentError, msg, fn ->
        Module.create(
          Module.concat(P, to_string(index)),
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
