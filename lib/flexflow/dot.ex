defmodule Flexflow.Dot do
  @moduledoc """
  * https://en.wikipedia.org/wiki/DOT_(graph_description_language)
  * https://github.com/TLmaK0/gravizo
  * https://gravizo.com/
  * http://www.graphviz.org/doc/info/attrs.html
  """

  alias Flexflow.DotProtocol

  verify_dot =
    [__DIR__, "../../README.md"]
    |> Path.join()
    |> File.read!()
    |> String.split("custom_mark")
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
      case DotProtocol.attributes(p) do
        [] ->
          ""

        attributes ->
          s = Enum.map_join(attributes, ",", fn {k, v} -> "#{k}=#{v}" end)
          " [#{s}]"
      end

    DotProtocol.prefix(p) <> DotProtocol.name(p) <> attributes <> DotProtocol.suffix(p)
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

  def name(%{
        __definitions__: definitions,
        events: events,
        transitions: transitions,
        __graphviz__: attributes
      }) do
    attributes_str = Enum.map_join(attributes, fn {k, v} -> "  #{k} =#{v};\n" end)

    str =
      definitions
      |> Enum.map(fn
        {:event, key} -> Map.fetch!(events, key)
        {:transition, key} -> Map.fetch!(transitions, key)
      end)
      |> Enum.map_join(&Flexflow.Dot.serialize/1)

    attributes_str <> str
  end
end

defimpl Flexflow.DotProtocol, for: Flexflow.Event do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"
  def name(%{name: name}), do: Flexflow.Dot.escape(name)

  def attributes(%{name: name, __graphviz__: attributes}),
    do: [label: inspect(name)] ++ attributes
end

defimpl Flexflow.DotProtocol, for: Flexflow.Transition do
  def prefix(_), do: "  "
  def suffix(_), do: ";\n"

  def name(%{from: {_, from_name}, to: {_, to_name}}),
    do: "#{Flexflow.Dot.escape(from_name)} -> #{Flexflow.Dot.escape(to_name)}"

  def attributes(%{name: name, __graphviz__: attributes}),
    do: [label: inspect(name)] ++ attributes
end
