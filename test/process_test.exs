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
    {:ok, pid} = Flexflow.ProcessManager.server({P1, "p1"})
    {:exist, pid2} = Flexflow.ProcessManager.server({P1, "p1"})
    assert pid == pid2
    process = Flexflow.ProcessServer.state(pid)
    assert process.id == "p1"

    assert Flexflow.ProcessManager.children(P1) == [
             %{kind: :worker, module: Flexflow.ProcessServer, pid: pid}
           ]
  end
end
