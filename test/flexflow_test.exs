defmodule FlexflowTest do
  use ExUnit.Case, async: true
  doctest Flexflow

  @moduletag capture_log: true
  @moduletag :basic

  # alias Flexflow.Event
  # alias Flexflow.State

  setup_all do
    []
  end

  test "version" do
    assert Flexflow.version()
  end

  # test "p2" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   p = Flexflow.Process.new(P2, name)
  #   assert p.state == :created
  # end

  # @data %{
  #   """
  #     state {N1, :n}, type: :start
  #     state :n2
  #     state N3, type: :end
  #     event T1, :n ~> N3
  #     event T2, :n ~> :n2
  #   """ => :ok,
  #   """
  #     state Start
  #     state :foo
  #     state N3, type: :end
  #     event T1, :start ~> N3
  #     event T2, :start ~> :foo
  #   """ => :ok,
  #   "" => "State is empty",
  #   """
  #     state N1, type: :start
  #     state N2, type: :end
  #   """ => "Event is empty",
  #   """
  #     state N0
  #   """ => "`Elixir.N0` should have a `name/0` function",
  #   """
  #     state N1
  #     state N2
  #     state N1
  #     event T1, N1 ~> N2
  #   """ => "State `n1` is defined twice",
  #   """
  #     state Start
  #     state {N3, "n3"}, type: :end
  #     event T1, :start ~> "n3"
  #   """ => "Name `n3` should be an atom",
  #   """
  #     state N1, type: :start
  #     state N2, type: :end
  #     event T1, :n1 ~> N4
  #   """ => "`{FlexflowDemoTest.N4, :n4}` is not defined",
  #   """
  #     state N1, type: :start
  #     state N2, type: :end
  #     event T1, :n1 ~> :n2
  #     event T2, :n1 ~> :n2
  #   """ => "Event `{{FlexflowDemoTest.N1, :n1}, {FlexflowDemoTest.N2, :n2}}` is defined twice",
  #   """
  #     state Start
  #     state End
  #     state N1
  #     event {T1, :t}, Start ~> End
  #     event {T1, :t}, N1 ~> End
  #   """ => "Event `{FlexflowDemoTest.T1, :t}` is defined twice",
  #   """
  #     state N1
  #     state N2
  #     event T1, N1 ~> N2
  #   """ => "Need a start state",
  #   """
  #     state N1, type: :start
  #     state N2, type: :start
  #     event T1, N1 ~> N2
  #   """ => "Multiple start state found",
  #   """
  #     state N1, type: :start
  #     state N2
  #     state N3, type: :end
  #     event T1, N1 ~> N2
  #   """ => "In edges of `{FlexflowDemoTest.N3, :n3}` is empty",
  #   """
  #     state N1, type: :start
  #     state N2
  #     state N3, type: :end
  #     event T1, N2 ~> N3
  #   """ => "Out edges of `{FlexflowDemoTest.N1, :n1}` is empty",
  #   """
  #     state N1, type: :start
  #     state N2
  #     state N3, type: :end
  #     event T1, N1 ~> N3
  #   """ => "`{FlexflowDemoTest.N2, :n2}` is isolated",
  #   """
  #     state N1, type: :start
  #     state N3, type: :end
  #     event T1, :n ~> N3
  #   """ => "`{Flexflow.States.Bypass, :n}` is not defined",
  #   """
  #     state {N1, :n}, type: :start
  #     state {N2, :n}
  #     state N3, type: :end
  #     event T1, :n ~> N3
  #   """ => "State `n` is defined twice"
  # }

  @data %{}

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
