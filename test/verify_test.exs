defmodule VerifyTest do
  use ExUnit.Case, async: true

  @moduletag capture_log: true
  @moduletag :verify

  test "module" do
    assert Verify.new("verify").id == "verify"
  end
end
