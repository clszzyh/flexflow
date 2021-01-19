defprotocol Flexflow.Dot do
  @spec serialize(term) :: binary()
  def serialize(term)
end

defimpl Flexflow.Dot, for: Flexflow.Process do
  @prefix "digraph G {\n"
  @suffix "}"

  def serialize(%Flexflow.Process{nodes: nodes, transitions: transitions}) do
    str =
      nodes
      |> Map.values()
      |> Kernel.++(Map.values(transitions))
      |> Enum.map_join("", &Flexflow.Dot.serialize/1)

    @prefix <> str <> @suffix
  end
end

defimpl Flexflow.Dot, for: Flexflow.Node do
  def serialize(%Flexflow.Node{name: name}) do
    "  #{name} [label=#{name}];\n"
  end
end

defimpl Flexflow.Dot, for: Flexflow.Transition do
  def serialize(%Flexflow.Transition{
        display: display,
        from: {_, from_name},
        to: {_, to_name}
      }) do
    "  #{from_name} -> #{to_name} [label=#{display}];\n"
  end
end
