defmodule Flexflow.Dot do
  @moduledoc """
  * https://en.wikipedia.org/wiki/DOT_(graph_description_language)
  * https://github.com/TLmaK0/gravizo
  * https://gravizo.com/
  * http://www.graphviz.org/doc/info/attrs.html
  """

  verify_dot =
    [__DIR__, "../../README.md"]
    |> Path.join()
    |> File.read!()
    |> String.split("custom_mark10")
    |> Enum.fetch!(2)
    |> String.trim()
    |> inspect

  @doc """
  ## Example

      iex> #{__MODULE__}.serialize(Review.new())
      #{verify_dot}
  """
  def serialize(p) do
    attributes =
      case Flexflow.DotProtocol.attributes(p) do
        [] ->
          ""

        attributes ->
          s = Enum.map_join(attributes, ",", fn {k, v} -> "#{k}=#{v}" end)
          " [#{s}]"
      end

    Flexflow.DotProtocol.prefix(p) <>
      Flexflow.DotProtocol.name(p) <> attributes <> Flexflow.DotProtocol.suffix(p)
  end

  def escape(name) when is_binary(name) do
    String.replace(name, " ", "_")
  end
end

defprotocol Flexflow.DotProtocol do
  def prefix(term)
  def suffix(term)
  def name(term)
  def attributes(term)
end

defimpl Flexflow.DotProtocol, for: Flexflow.Process do
  def prefix(%{name: name}), do: "digraph #{Flexflow.Dot.escape(name)} {\n"
  def suffix(_), do: "}\n//"
  def attributes(_), do: []

  def name(%Flexflow.Process{
        __identities__: identities,
        nodes: nodes,
        transitions: transitions,
        __graphviz_attributes__: attributes
      }) do
    attributes_str = Enum.map_join(attributes, fn {k, v} -> "  #{k} =#{v};\n" end)

    identities =
      Enum.map(identities, fn
        {:node, key} -> Map.fetch!(nodes, key)
        {:transition, key} -> Map.fetch!(transitions, key)
      end)

    str = Enum.map_join(identities, &Flexflow.Dot.serialize/1)

    attributes_str <> str
  end
end

defimpl Flexflow.DotProtocol, for: Flexflow.Node do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"
  def name(%{name: name}), do: Flexflow.Dot.escape(name)

  def attributes(%{name: name, __graphviz_attributes__: attributes}),
    do: [label: inspect(name)] ++ attributes
end

defimpl Flexflow.DotProtocol, for: Flexflow.Transition do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"

  def name(%{from: {_, from_name}, to: {_, to_name}}),
    do: "#{Flexflow.Dot.escape(from_name)} -> #{Flexflow.Dot.escape(to_name)}"

  def attributes(%{module: module, __graphviz_attributes__: attributes}),
    do: [label: inspect(module.name())] ++ attributes
end
