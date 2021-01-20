defmodule Flexflow.Dot do
  @moduledoc """
  * https://en.wikipedia.org/wiki/DOT_(graph_description_language)
  * https://github.com/TLmaK0/gravizo
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

      iex> #{__MODULE__}.serialize(Verify.new())
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
end

defprotocol Flexflow.DotProtocol do
  def prefix(term)
  def suffix(term)
  def name(term)
  def attributes(term)
end

defimpl Flexflow.DotProtocol, for: Flexflow.Process do
  def prefix(%{name: name}), do: "digraph #{name} {\n"
  def suffix(_), do: "}\n//"
  def attributes(_), do: []

  def name(%Flexflow.Process{
        __identities__: identities,
        nodes: nodes,
        transitions: transitions,
        __attributes__: attributes
      }) do
    attributes_str = Enum.map_join(attributes, fn {k, v} -> "  #{k} = #{v};\n" end)

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
  def name(%{name: name}), do: name
  # def labels(%{name: "rejected"}), do: [label: "\"{{O|6}|1100}\"", shape: "box"]
  def attributes(%{name: name, __attributes__: attributes}), do: [label: name] ++ attributes
end

defimpl Flexflow.DotProtocol, for: Flexflow.Transition do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"
  def name(%{from: {_, from_name}, to: {_, to_name}}), do: "#{from_name} -> #{to_name}"

  def attributes(%{module: module, __attributes__: attributes}),
    do: [label: module.name()] ++ attributes
end
