# credo:disable-for-next-line Credo.Check.Readability.ModuleDoc
defmodule Flexflow.Processes.Basic do
  use Flexflow.Process

  defnode Nodes.Start
  defnode Nodes.End

  deftransition Transitions.Pass, {Nodes.Start, Nodes.End}
end
