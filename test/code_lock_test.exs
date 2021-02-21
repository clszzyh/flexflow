defmodule CodeLockTest do
  use ExUnit.Case, async: true
  doctest CodeLock

  alias CodeLock.Door
  alias Flexflow.Process

  @moduletag capture_log: true

  test "basic" do
    name = to_string(elem(__ENV__.function, 0))
    {:ok, %Process{} = p} = Flexflow.Process.new(Door, name)

    assert p.id == name
  end

  test "process" do
    name = to_string(elem(__ENV__.function, 0))
    key = {Door, name}
    assert Flexflow.server(key) == {:error, "Need a 6-length code"}
    {:ok, srv} = Flexflow.server(key, %{code: "123123"})
    assert is_pid(srv)
    {:ok, ^srv} = Flexflow.server(key)
    {:ok, %Process{} = p} = Flexflow.state(key)
    assert p.id == name
    assert p.states[:locked].context == %{buttons: [], code: ["3", "2", "1", "3", "2", "1"]}
  end

  test "unlock" do
    name = to_string(elem(__ENV__.function, 0))
    key = {Door, name}
    code = "123123"
    {:ok, _} = Flexflow.server(key, %{code: code})

    {:ok, %Process{} = p} = Flexflow.state(key)
    assert p.state == :locked
    :ok = Flexflow.cast(key, {:event, {:button, "1"}})
    :ok = Flexflow.cast(key, {:event, {:button, "2"}})
    :ok = Flexflow.cast(key, {:event, {:button, "3"}})
    :ok = Flexflow.cast(key, {:event, {:button, "1"}})
    :ok = Flexflow.cast(key, {:event, {:button, "2"}})

    {:ok, %Process{} = p} = Flexflow.state(key)
    assert p.state == :locked
    assert p.states[:locked].context.buttons == ["2", "1", "3", "2", "1"]

    :ok = Flexflow.cast(key, {:event, {:button, "3"}})

    {:ok, %Process{} = p} = Flexflow.state(key)
    assert p.states[:locked].context.buttons == []
    assert p.state == :opened
  end
end
