defmodule ProcessTest do
  use ExUnit.Case, async: true

  doctest Flexflow.ProcessRegistry

  @moduletag capture_log: true
  @moduletag :process

  setup_all do
    _ = Flexflow.ModuleRegistry.state()
    []
  end

  test "Flexflow.ModuleRegistry" do
    pid = Flexflow.ModuleRegistry |> Process.whereis()
    assert is_pid(pid)
    assert Flexflow.ModuleRegistry.find(Flexflow.Process, "p1_new")
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

  test "start process" do
    {:ok, pid} = P1.start("p1")
    {:exist, pid2} = P1.start("p1")
    assert pid == pid2
    assert pid == Flexflow.ProcessSupervisor.pid({P1, "p1"})

    server_pid = Flexflow.ProcessServer.pid({P1, "p1"})
    node_n3_pid = Flexflow.NodeServer.pid({P1, "p1", N3, "n3"})
    transition_t2_pid = Flexflow.TransitionServer.pid({P1, "p1", T2, "t2_by_n2"})

    assert MapSet.new(Supervisor.which_children(pid)) ==
             MapSet.new([
               {Flexflow.ProcessServer, server_pid, :worker, [Flexflow.ProcessServer]},
               {Flexflow.NodeServer, node_n3_pid, :worker, [Flexflow.NodeServer]},
               {Flexflow.TransitionServer, transition_t2_pid, :worker,
                [Flexflow.TransitionServer]}
             ])

    process = Flexflow.ProcessServer.state(server_pid)
    assert process.id == "p1"

    assert Flexflow.ProcessManager.children(P1) == [
             %{kind: :supervisor, module: Flexflow.ProcessSupervisor, pid: pid}
           ]
  end
end
