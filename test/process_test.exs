defmodule ProcessTest do
  use ExUnit.Case, async: true

  doctest Flexflow.ProcessRegistry

  @moduletag :process

  setup_all do
    _ = Flexflow.ModuleRegistry.state()
    []
  end

  test "Flexflow.ModuleRegistry" do
    pid = Flexflow.ModuleRegistry |> Process.whereis()
    assert is_pid(pid)
    assert Flexflow.ModuleRegistry.find(Flexflow.Process, :p1)
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
end
