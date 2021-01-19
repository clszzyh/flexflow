defmodule VerifyTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true
  @moduletag :verify

  test "module" do
    assert Verify.new("verify").id == "verify"
  end

  test "dot" do
    dot =
      [__DIR__, "../README.md"]
      |> Path.join()
      |> File.read!()
      |> String.split("custom_mark10")
      |> Enum.fetch!(2)
      |> String.trim()

    assert Flexflow.Dot.serialize(Verify.new()) == dot
  end
end
