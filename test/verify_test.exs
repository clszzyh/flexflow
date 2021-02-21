defmodule ReviewTest do
  use ExUnit.Case, async: true
  # doctest Flexflow.Dot

  @moduletag capture_log: true
  @moduletag :review

  test "module" do
    name = to_string(elem(__ENV__.function, 0))
    assert Review.new(name).id == name
  end
end
