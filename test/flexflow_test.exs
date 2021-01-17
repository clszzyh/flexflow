defmodule FlexflowTest do
  use ExUnit.Case
  doctest Flexflow

  alias Flexflow.Event, as: V
  alias Flexflow.Transition, as: T

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

    t1 = %T{module: T1, opts: [foo: :baz], from: {E1, nil}, to: {E2, nil}}
    t2 = %T{module: T2, from: {E2, nil}, to: {E3, nil}}

    assert graph ==
             Graph.new()
             |> Graph.add_vertices([e1, e2, e3])
             |> Graph.add_edges([
               Graph.Edge.new(e1, e2, label: t1),
               Graph.Edge.new(e2, e3, label: t2)
             ])
  end

  test "compile raise" do
    map = %{
      quote do
      end => "Event is empty!",
      quote do
        defevent E1
      end => "Transition is empty!",
      quote do
        defevent E0
      end => "E0 should implement Elixir.Flexflow.Event",
      quote do
        defevent E1
        defevent E2
        defevent E1
        deftransition T1, {E1, E2}
      end => "{E1, nil} is defined twice!",
      quote do
        defevent E1
        defevent E2
        defevent E3
        deftransition T1, {E1, E4}
      end => "{E4, nil} is not defined!",
      quote do
        defevent E1
        defevent E2
        defevent E3
        deftransition T1, {E1, E1}
      end => "{E1, nil} cannot target to self!"
    }

    for {ast, msg} <- map do
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
