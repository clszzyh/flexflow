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

    assert graph ==
             Graph.new()
             |> Graph.add_vertices([{E1, nil}, {E2, nil}, {E3, nil}])
             |> Graph.add_edges([{{E1, nil}, {E2, nil}}])
  end
end
