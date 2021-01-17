# credo:disable-for-next-line Credo.Check.Readability.ModuleDoc
defmodule Flexflow.Processes.Basic do
  use Flexflow.Process

  defevent Events.Start
  defevent Events.End

  deftransition Transitions.Pass, {Events.Start, Events.End}
end
