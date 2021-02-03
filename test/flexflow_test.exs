defmodule FlexflowTest do
  use ExUnit.Case, async: true
  doctest Flexflow

  @moduletag capture_log: true
  @moduletag :basic

  alias Flexflow.Activity
  alias Flexflow.Gateway

  alias FlexflowDemoTest.{N1, N2, N3, N4}
  alias FlexflowDemoTest.{P1, P2}
  alias FlexflowDemoTest.{T1, T2}

  setup_all do
    []
  end

  test "version" do
    assert Flexflow.version()
  end

  test "p1" do
    name = to_string(elem(__ENV__.function, 0))
    assert P1.module_info()
    assert P1.new(name, %{parent: {P1, "foo"}}).parent == {P1, "foo"}
    assert P1.new(name, %{parent: {P1, "foo"}}).__args__ == %{}
    assert P1.new(name, %{foo: :bar}).__args__ == %{foo: :bar}
    assert P1.new(name, %{foo: :bar}).id == name
    assert P1.new().name == :p1_new
    assert P1.new().__opts__ == [hello: %{foo: :zzzz}]
    assert P1.new().module == P1

    n1_s = {N1, :n1}
    n2_s = {N2, :n2}
    n3_s = {N3, :n3}
    n4_s = {N4, :n4}

    t1_s = {T1, :t1_n1}
    t2_s = {T2, :t2_n2}
    t3_s = {T2, :t2_name}

    t1 = %Gateway{module: T1, name: :t1_n1, __opts__: [foo: :baz], from: n1_s, to: n2_s}
    t2 = %Gateway{module: T2, name: :t2_n2, from: n2_s, to: n3_s}
    t3 = %Gateway{module: T2, name: :t2_name, from: n2_s, to: n4_s}

    n1 = Activity.new({n1_s, foo: %{aaa: :bbb}, type: :start})
    n2 = Activity.new({n2_s, []})
    n3 = Activity.new({n3_s, async: true})
    n4 = Activity.new({n4_s, type: :end})

    n1 = %{n1 | __out_edges__: [{t1_s, n2_s}]}
    n2 = %{n2 | __in_edges__: [{t1_s, n1_s}], __out_edges__: [{t2_s, n3_s}, {t3_s, n4_s}]}
    n3 = %{n3 | __in_edges__: [{t2_s, n2_s}]}
    n4 = %{n4 | __in_edges__: [{t3_s, n2_s}]}

    assert P1.new().__definitions__ == [
             activity: n1_s,
             activity: n2_s,
             gateway: t1_s,
             activity: n3_s,
             activity: n4_s,
             gateway: t2_s,
             gateway: t3_s
           ]

    assert P1.new().activities == %{n1_s => n1, n2_s => n2, n3_s => n3, n4_s => n4}
    assert P1.new().gateways == %{t1_s => t1, t2_s => t2, t3_s => t3}
  end

  test "p2" do
    name = to_string(elem(__ENV__.function, 0))
    p = Flexflow.Process.new(P2, name)
    assert p.state == :created
  end

  @data %{
    """
      activity {N1, :n}, type: :start
      activity :n2
      activity N3, type: :end
      gateway T1, :n ~> N3
      gateway T2, :n ~> :n2
    """ => :ok,
    """
      activity Start
      activity :foo
      activity N3, type: :end
      gateway T1, :start ~> N3
      gateway T2, :start ~> :foo
    """ => :ok,
    "" => "Activity is empty",
    """
      activity N1, type: :start
      activity N2, type: :end
    """ => "Gateway is empty",
    """
      activity N0
    """ => "`Elixir.N0` should have a `name/0` function",
    """
      activity N1
      activity N2
      activity N1
      gateway T1, N1 ~> N2
    """ => "Activity `n1` is defined twice",
    """
      activity Start
      activity {N3, "n3"}, type: :end
      gateway T1, :start ~> "n3"
    """ => "Name `n3` should be an atom",
    """
      activity N1, type: :start
      activity N2, type: :end
      gateway T1, :n1 ~> N4
    """ => "`{FlexflowDemoTest.N4, :n4}` is not defined",
    """
      activity N1, type: :start
      activity N2, type: :end
      gateway T1, :n1 ~> :n2
      gateway T2, :n1 ~> :n2
    """ => "Gateway `{{FlexflowDemoTest.N1, :n1}, {FlexflowDemoTest.N2, :n2}}` is defined twice",
    """
      activity Start
      activity End
      activity N1
      gateway {T1, :t}, Start ~> End
      gateway {T1, :t}, N1 ~> End
    """ => "Gateway `{FlexflowDemoTest.T1, :t}` is defined twice",
    """
      activity N1
      activity N2
      gateway T1, N1 ~> N2
    """ => "Need a start activity",
    """
      activity N1, type: :start
      activity N2, type: :start
      gateway T1, N1 ~> N2
    """ => "Multiple start activity found",
    """
      activity N1, type: :start
      activity N2
      gateway T1, N1 ~> N2
    """ => "Need one or more end activity",
    """
      activity N1, type: :start
      activity N2
      activity N3, type: :end
      gateway T1, N1 ~> N2
    """ => "In edges of `{FlexflowDemoTest.N3, :n3}` is empty",
    """
      activity N1, type: :start
      activity N2
      activity N3, type: :end
      gateway T1, N2 ~> N3
    """ => "Out edges of `{FlexflowDemoTest.N1, :n1}` is empty",
    """
      activity N1, type: :start
      activity N2
      activity N3, type: :end
      gateway T1, N1 ~> N3
    """ => "`{FlexflowDemoTest.N2, :n2}` is isolated",
    """
      activity N1, type: :start
      activity N3, type: :end
      gateway T1, :n ~> N3
    """ => "`{Flexflow.Activities.Bypass, :n}` is not defined",
    """
      activity {N1, :n}, type: :start
      activity {N2, :n}
      activity N3, type: :end
      gateway T1, :n ~> N3
    """ => "Activity `n` is defined twice"
  }

  for {{code, msg}, index} <- Enum.with_index(@data) do
    module_name = Module.concat(["NP#{index}"])

    body = """
    defmodule #{module_name} do
      use Flexflow.Process
      alias FlexflowDemoTest.{N1, N2, N3, N4}, warn: false
      alias FlexflowDemoTest.{T1, T2}, warn: false
      #{code}
    end
    """

    name = "[#{index}] #{msg}"

    test_ast =
      case msg do
        :ok ->
          quote do
            test unquote(name) do
              Code.eval_string(unquote(body))
            end
          end

        msg ->
          quote do
            test unquote(name) do
              assert_raise ArgumentError, unquote(msg), fn ->
                Code.eval_string(unquote(body))
              end
            end
          end
      end

    Module.eval_quoted(__MODULE__, test_ast)
  end
end
