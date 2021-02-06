defmodule FlexflowTest do
  use ExUnit.Case, async: true
  doctest Flexflow

  @moduletag capture_log: true
  @moduletag :basic

  alias Flexflow.State
  alias Flexflow.Event

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

    t1 = %Event{module: T1, name: :t1_n1, __opts__: [foo: :baz], from: n1_s, to: n2_s}
    t2 = %Event{module: T2, name: :t2_n2, from: n2_s, to: n3_s}
    t3 = %Event{module: T2, name: :t2_name, from: n2_s, to: n4_s}

    n1 = State.new({n1_s, foo: %{aaa: :bbb}, type: :start})
    n2 = State.new({n2_s, []})
    n3 = State.new({n3_s, async: true})
    n4 = State.new({n4_s, type: :end})

    n1 = %{n1 | __out_edges__: [{t1_s, n2_s}]}
    n2 = %{n2 | __in_edges__: [{t1_s, n1_s}], __out_edges__: [{t2_s, n3_s}, {t3_s, n4_s}]}
    n3 = %{n3 | __in_edges__: [{t2_s, n2_s}]}
    n4 = %{n4 | __in_edges__: [{t3_s, n2_s}]}

    assert P1.new().__definitions__ == [
             state: n1_s,
             state: n2_s,
             event: t1_s,
             state: n3_s,
             state: n4_s,
             event: t2_s,
             event: t3_s
           ]

    assert P1.new().states == %{n1_s => n1, n2_s => n2, n3_s => n3, n4_s => n4}
    assert P1.new().events == %{t1_s => t1, t2_s => t2, t3_s => t3}
  end

  test "p2" do
    name = to_string(elem(__ENV__.function, 0))
    p = Flexflow.Process.new(P2, name)
    assert p.state == :created
  end

  @data %{
    """
      state {N1, :n}, type: :start
      state :n2
      state N3, type: :end
      event T1, :n ~> N3
      event T2, :n ~> :n2
    """ => :ok,
    """
      state Start
      state :foo
      state N3, type: :end
      event T1, :start ~> N3
      event T2, :start ~> :foo
    """ => :ok,
    "" => "State is empty",
    """
      state N1, type: :start
      state N2, type: :end
    """ => "Event is empty",
    """
      state N0
    """ => "`Elixir.N0` should have a `name/0` function",
    """
      state N1
      state N2
      state N1
      event T1, N1 ~> N2
    """ => "State `n1` is defined twice",
    """
      state Start
      state {N3, "n3"}, type: :end
      event T1, :start ~> "n3"
    """ => "Name `n3` should be an atom",
    """
      state N1, type: :start
      state N2, type: :end
      event T1, :n1 ~> N4
    """ => "`{FlexflowDemoTest.N4, :n4}` is not defined",
    """
      state N1, type: :start
      state N2, type: :end
      event T1, :n1 ~> :n2
      event T2, :n1 ~> :n2
    """ => "Event `{{FlexflowDemoTest.N1, :n1}, {FlexflowDemoTest.N2, :n2}}` is defined twice",
    """
      state Start
      state End
      state N1
      event {T1, :t}, Start ~> End
      event {T1, :t}, N1 ~> End
    """ => "Event `{FlexflowDemoTest.T1, :t}` is defined twice",
    """
      state N1
      state N2
      event T1, N1 ~> N2
    """ => "Need a start state",
    """
      state N1, type: :start
      state N2, type: :start
      event T1, N1 ~> N2
    """ => "Multiple start state found",
    """
      state N1, type: :start
      state N2
      event T1, N1 ~> N2
    """ => "Need one or more end state",
    """
      state N1, type: :start
      state N2
      state N3, type: :end
      event T1, N1 ~> N2
    """ => "In edges of `{FlexflowDemoTest.N3, :n3}` is empty",
    """
      state N1, type: :start
      state N2
      state N3, type: :end
      event T1, N2 ~> N3
    """ => "Out edges of `{FlexflowDemoTest.N1, :n1}` is empty",
    """
      state N1, type: :start
      state N2
      state N3, type: :end
      event T1, N1 ~> N3
    """ => "`{FlexflowDemoTest.N2, :n2}` is isolated",
    """
      state N1, type: :start
      state N3, type: :end
      event T1, :n ~> N3
    """ => "`{Flexflow.States.Bypass, :n}` is not defined",
    """
      state {N1, :n}, type: :start
      state {N2, :n}
      state N3, type: :end
      event T1, :n ~> N3
    """ => "State `n` is defined twice"
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
