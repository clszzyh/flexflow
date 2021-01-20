defmodule FlexflowVerifyTest do
  @moduledoc false

  @external_resource Path.join([__DIR__, "../../README.md"])

  @external_resource
  |> File.read!()
  |> String.split("<!-- MDOC -->")
  |> Enum.fetch!(1)
  |> EarmarkParser.as_ast()
  |> case do
    {:ok, ast, _} ->
      ast
      |> Enum.find_value(fn x ->
        case x do
          {"pre", _, [{"code", [{"class", "elixir"} | _], [code], _}], _} ->
            {{:module, Verify, _bytecode, :ok}, _} = Code.eval_string(code)

          _ ->
            nil
        end
      end)

    _ ->
      raise ArgumentError, "Parse README.md error!"
  end
end
