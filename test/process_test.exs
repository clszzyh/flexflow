defmodule ProcessTest do
  use ExUnit.Case, async: true

  doctest Flexflow.ProcessRegistry

  @moduletag capture_log: true
  @moduletag :process

  setup_all do
    _ = Flexflow.ModuleRegistry.state()
    []
  end

  test "history" do
    history = %Flexflow.History{name: :a, event: :process_init}
    assert Flexflow.History.put({P1, "a"}, history) == true
    assert Flexflow.History.get({P1, "a"}) == [history]
    assert Flexflow.history({P1, "a"}) == [history]
  end

  test "Flexflow.TaskSupervisor" do
    pid = Flexflow.TaskSupervisor |> Process.whereis()
    assert is_pid(pid)
  end

  test "Flexflow.ModuleRegistry" do
    pid = Flexflow.ModuleRegistry |> Process.whereis()
    assert is_pid(pid)
    assert Flexflow.ModuleRegistry.find(Flexflow.Process, :p1_new)
  end

  test "Flexflow.ProcessParentManager" do
    pid = Flexflow.ProcessParentManager |> Process.whereis()
    assert is_pid(pid)
    assert [_ | _] = Flexflow.ProcessParentManager.children()
  end

  test "Flexflow.ProcessManager" do
    pid = Flexflow.ProcessManager.pid(P1)
    assert is_pid(pid)
    pids = for %{pid: pid} <- Flexflow.ProcessParentManager.children(), do: pid
    assert pid in pids
  end

  test "process p1" do
    {:ok, pid} = Flexflow.start({P1, "p1"})
    {:exist, pid2} = Flexflow.start({P1, "p1"})
    assert pid == pid2

    assert Flexflow.ProcessManager.children(P1) == [
             %Flexflow.ProcessManager{pid: pid, id: "p1", name: :p1_new}
           ]

    server_pid = Flexflow.ProcessServer.pid({P1, "p1"})

    assert server_pid == pid

    process = Flexflow.state({P1, "p1"})
    assert process.id == "p1"
    assert process.state == :waiting
    assert process.events[{N1, :n1}].state == :completed
    assert process.events[{N2, :n2}].state == :initial
    assert process.gateways[{T1, :t1_n1}].state == :initial

    Process.sleep(60)
    process = Flexflow.state({P1, "p1"})
    assert process.events[{N3, :n3}].state == :initial
  end

  test "p2 slow ok" do
    {:ok, _pid} = Flexflow.start({P2, "slow_ok"}, %{slow: :ok, sleep: 50})
    Process.sleep(60)
    process = Flexflow.state({P2, "slow_ok"})
    assert process.events[{P2.Slow, :slow}].state == :initial
    assert process.events[{P2.Slow, :slow}].__context__.state == :ok
  end

  test "p2 slow other" do
    {:ok, _pid} = Flexflow.start({P2, "slow_other"}, %{slow: :other, sleep: 50})
    Process.sleep(60)
    process = Flexflow.state({P2, "slow_other"})
    assert process.events[{P2.Slow, :slow}].state == :initial
    assert process.events[{P2.Slow, :slow}].__context__.state == :ok
    assert process.events[{P2.Slow, :slow}].__context__.result == :other
  end

  test "p2 slow error" do
    {:ok, _pid} = Flexflow.start({P2, "slow_error"}, %{slow: :error, sleep: 50})
    Process.sleep(60)
    process = Flexflow.state({P2, "slow_error"})
    assert process.events[{P2.Slow, :slow}].state == :error
    assert process.events[{P2.Slow, :slow}].__context__.state == :error
    assert process.events[{P2.Slow, :slow}].__context__.result == :custom_error
  end

  # test "p2 timeout" do
  #   {:ok, _pid} = Flexflow.start({P2, "p2 timeout"}, %{slow: :error, sleep: 10_000})
  #   Process.sleep(12_000)
  #   process = Flexflow.state({P2, "p2 timeout"})
  #   assert process.events[{P2.Slow, "slow"}].state == :error
  #   assert process.events[{P2.Slow, "slow"}].__context__.state == :error
  #   assert process.events[{P2.Slow, "slow"}].__context__.result == :custom_error
  # end

  test "p2 slow raise" do
    {:ok, _pid} = Flexflow.start({P2, "slow_raise"}, %{slow: :raise, sleep: 50})
    Process.sleep(60)
    process = Flexflow.state({P2, "slow_raise"})
    assert process.events[{P2.Slow, :slow}].state == :error
    assert process.events[{P2.Slow, :slow}].__context__.state == :error

    assert {%RuntimeError{message: "fooo"}, [_ | _]} =
             process.events[{P2.Slow, :slow}].__context__.result
  end
end
