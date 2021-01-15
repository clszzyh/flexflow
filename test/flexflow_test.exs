defmodule FlexflowTest do
  use ExUnit.Case
  doctest Flexflow

  test "version" do
    assert Flexflow.version()
  end
end
