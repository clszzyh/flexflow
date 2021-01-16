defmodule FlexflowTest do
  use ExUnit.Case
  doctest Flexflow

  alias Flexflow.Event, as: V

  test "version" do
    assert Flexflow.version()
  end

  test "p1" do
    assert P1.module_info()
    assert P1.new()
    assert P1.new(%{name: :foo}).name == :foo
    assert P1.new(name: :foo).name == :foo
    graph = P1.__self__().graph
    assert graph.__struct__ == Graph

    e1 = %V{module: E1, id: nil, opts: [foo: :bar]}
    e2 = %V{module: E2, id: nil}
    e3 = %V{module: E3, id: nil}

    assert graph ==
             Graph.new()
             |> Graph.add_vertices([e1, e2, e3])
             |> Graph.add_edges([Graph.Edge.new(e1, e2, label: T1)])
  end
end
