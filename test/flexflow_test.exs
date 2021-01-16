defmodule FlexflowTest do
  use ExUnit.Case
  doctest Flexflow

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

    e1 = {E1, nil}
    e2 = {E2, nil}
    e3 = {E3, nil}

    assert graph ==
             Graph.new()
             |> Graph.add_vertices([e1, e2, e3])
             |> Graph.add_edges([
               Graph.Edge.new(e1, e2, label: T1)
             ])
  end
end
