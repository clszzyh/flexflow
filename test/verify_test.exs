defmodule ReviewTest do
  use ExUnit.Case, async: true
  doctest Flexflow.Dot

  @moduletag capture_log: true
  @moduletag :review

  test "module" do
    assert Review.new("verify").id == "verify"
  end
end
