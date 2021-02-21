defmodule ProcessTest do
  use ExUnit.Case, async: true

  doctest Flexflow.EventDispatcher
  doctest Flexflow.ProcessRegistry

  @moduletag capture_log: true
  @moduletag :process

  setup_all do
    []
  end

  test "history" do
    name = to_string(elem(__ENV__.function, 0))
    assert Flexflow.History.put({P1, name}, :process_init) == :ok
    assert [_ | _] = Flexflow.history({P1, name})
  end

  # test "start_child" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, _pid} = Flexflow.start({P1, name})
  #   {:ok, child_pid} = Flexflow.start_child({P1, name}, {P1, "child"})
  #   {:error, {:exist, child_pid2}} = Flexflow.start_child({P1, name}, {P1, "child"})
  #   assert child_pid == child_pid2
  #   :ok = Flexflow.stop({P1, "child"})
  #   {:ok, _child_pid} = Flexflow.start_child({P1, name}, {P1, "child2"})
  #   process = Flexflow.state({P1, name})
  #   child_process = Flexflow.state({P1, "child2"})
  #   assert process.childs == [{P1, "child2"}, {P1, "child"}]
  #   assert child_process.parent == {P1, name}
  #   assert process.request_id == child_process.request_id
  #   :ok = Flexflow.stop({P1, "child2"})
  #   :ok = Flexflow.stop({P1, name})
  # end

  # test "Flexflow.TaskSupervisor" do
  #   pid = Flexflow.TaskSupervisor |> Process.whereis()
  #   assert is_pid(pid)
  # end

  # test "Flexflow.ProcessParentManager" do
  #   pid = Flexflow.ProcessParentManager |> Process.whereis()
  #   assert is_pid(pid)
  #   assert [_ | _] = Flexflow.ProcessParentManager.children()
  # end

  # test "Flexflow.ProcessManager" do
  #   pid = Flexflow.ProcessManager.pid(P1)
  #   assert is_pid(pid)
  #   pids = for %{pid: pid} <- Flexflow.ProcessParentManager.children(), do: pid
  #   assert pid in pids
  # end

  # test "kill" do
  #   assert {:ok, {P1, "kill"}} = Flexflow.History.ensure_new({P1, "kill"})
  #   {:ok, pid} = Flexflow.start({P1, "kill"})
  #   assert {:error, :already_exists} = Flexflow.History.ensure_new({P1, "kill"})
  #   true = Process.exit(pid, :kill)
  #   assert Process.info(pid) == nil
  #   {:error, :already_exists} = Flexflow.start({P1, "kill"})
  #   {:ok, pid2} = Flexflow.start({P1, "kill2"})
  #   true = Process.exit(pid2, :normal)
  #   refute Process.info(pid2) == nil
  #   {:ok, srv} = Flexflow.ProcessManager.server_pid(P1)
  #   assert is_pid(srv)
  #   :ok = Flexflow.stop({P1, "kill2"})
  #   assert Process.info(pid2) == nil
  # end

  # test "process p1" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, pid} = Flexflow.start({P1, name})
  #   {:exist, pid2} = Flexflow.server({P1, name})
  #   pid3 = Flexflow.pid({P1, name})
  #   assert pid == pid2
  #   assert pid == pid3
  #   assert [_ | _] = Flexflow.history({P1, name})
  #   assert Flexflow.ProcessManager.children(P1) == [
  #            %Flexflow.ProcessManager{pid: pid, id: name, name: :p1_new, state: :a}
  #          ]
  #   server_pid = Flexflow.ProcessStatem.pid({P1, name})
  #   assert server_pid == pid
  #   process = Flexflow.state({P1, name})
  #   assert process.id == name
  #   assert process.state == :waiting
  #   assert process.states[{N1, :n1}].state == :completed
  #   assert process.states[{N2, :n2}].state == :initial
  #   assert process.events[{T1, :t1_n1}].state == :initial
  #   Process.sleep(60)
  #   process = Flexflow.state({P1, name})
  #   assert process.states[{N3, :n3}].state == :initial
  # end

  # test "p2 slow ok" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, _pid} = Flexflow.start({P2, name}, %{slow: :ok, sleep: 50})
  #   Process.sleep(60)
  #   process = Flexflow.state({P2, name})
  #   assert process.states[{P2.Slow, :slow}].state == :initial
  #   assert process.states[{P2.Slow, :slow}].context.state == :ok
  # end

  # test "p2 slow other" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, _pid} = Flexflow.start({P2, name}, %{slow: :other, sleep: 50})
  #   Process.sleep(60)
  #   process = Flexflow.state({P2, name})
  #   assert process.states[{P2.Slow, :slow}].state == :initial
  #   assert process.states[{P2.Slow, :slow}].context.state == :ok
  #   assert process.states[{P2.Slow, :slow}].context.result == :other
  # end

  # test "p2 slow error" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, _pid} = Flexflow.start({P2, name}, %{slow: :error, sleep: 50})
  #   Process.sleep(60)
  #   process = Flexflow.state({P2, name})
  #   assert process.states[{P2.Slow, :slow}].state == :error
  #   assert process.states[{P2.Slow, :slow}].context.state == :error
  #   assert process.states[{P2.Slow, :slow}].context.result == :custom_error
  # end

  # test "p2 slow raise" do
  #   name = to_string(elem(__ENV__.function, 0))
  #   {:ok, _pid} = Flexflow.start({P2, name}, %{slow: :raise, sleep: 50})
  #   Process.sleep(60)
  #   process = Flexflow.state({P2, name})
  #   assert process.states[{P2.Slow, :slow}].state == :error
  #   assert process.states[{P2.Slow, :slow}].context.state == :error
  #   assert {%RuntimeError{message: "fooo"}, [_ | _]} =
  #            process.states[{P2.Slow, :slow}].context.result
  # end
end
