defmodule Flexflow.Dot do
  @moduledoc """
  https://en.wikipedia.org/wiki/DOT_(graph_description_language)
  https://github.com/TLmaK0/gravizo
  """
  def serialize(p) do
    label =
      case Flexflow.DotProtocol.labels(p) do
        [] ->
          ""

        labels ->
          s = Enum.map_join(labels, ",", fn {k, v} -> "#{k}=#{v}" end)
          " [#{s}]"
      end

    Flexflow.DotProtocol.prefix(p) <>
      Flexflow.DotProtocol.name(p) <> label <> Flexflow.DotProtocol.suffix(p)
  end
end

defprotocol Flexflow.DotProtocol do
  def prefix(term)
  def suffix(term)
  def name(term)
  def labels(term)
end

defimpl Flexflow.DotProtocol, for: Flexflow.Process do
  def prefix(%{name: name}), do: "digraph #{name} {\n"
  def suffix(_), do: "}"
  def labels(_), do: []

  def name(%Flexflow.Process{nodes: nodes, transitions: transitions}) do
    nodes
    |> Map.values()
    |> Kernel.++(Map.values(transitions))
    |> Enum.map_join("", &Flexflow.Dot.serialize/1)
  end
end

defimpl Flexflow.DotProtocol, for: Flexflow.Node do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"
  def name(%{name: name}), do: name
  def labels(%{name: name}), do: [label: name]
end

defimpl Flexflow.DotProtocol, for: Flexflow.Transition do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"
  def name(%{from: {_, from_name}, to: {_, to_name}}), do: "#{from_name} -> #{to_name}"

  def labels(%{module: module, from: {_, name}, to: {_, name}}),
    do: [label: module.name(), style: "dotted"]

  def labels(%{module: module}), do: [label: module.name()]
end
