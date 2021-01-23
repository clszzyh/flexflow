# Flexflow

[![ci](https://github.com/clszzyh/flexflow/workflows/ci/badge.svg)](https://github.com/clszzyh/flexflow/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/flexflow)](http://hex.pm/packages/flexflow)
[![Hex.pm](https://img.shields.io/hexpm/dt/flexflow)](http://hex.pm/packages/flexflow)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/flexflow/readme.html)
[![Last Updated](https://img.shields.io/github/last-commit/clszzyh/flexflow.svg)](https://github.com/clszzyh/flexflow/commits/master)
![Lines of code](https://img.shields.io/tokei/lines/github/clszzyh/flexflow)

<!-- MDOC -->

## Usage

```elixir
defmodule Review do
  use Flexflow.Process, version: 1

  defmodule Reviewing do
    use Flexflow.Event
  end

  defmodule Submit do
    use Flexflow.Transition
  end

  ## Start event
  event {Start, "draft"}
  ## End event, `async` mode means this transition run's in a separated elixir process.
  event {End, "reviewed"}, async: true
  event {End, "canceled"}
  ## Intermediate event
  event "rejected"
  ## Custom event
  event Reviewing

  ## Define a transition
  ## `a ~> b` is a shortcut of `{a, b}`
  transition "modify1", "draft" ~> "draft"
  transition "cancel1", "draft" ~> "canceled"

  ## Custom transition
  transition Submit, "draft" ~> Reviewing

  transition "modify2", "rejected" ~> "rejected"
  transition "cancel2", "rejected" ~> "canceled"

  ## With custom name
  transition {Submit, "submit2"}, "rejected" ~> Reviewing

  transition "reject", Reviewing ~> "rejected"
  transition "agree", Reviewing ~> "reviewed"
end
```

<!-- MDOC -->

## Graphviz Dot

<details>
<summary><img src="https://g.gravizo.com/source/custom_mark?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md"></summary>

```dot
// custom_mark
digraph review {
  size ="4,4";
  draft [label="draft",shape=doublecircle,color=".7 .3 1.0"];
  reviewed [label="reviewed",style=bold,shape=circle,color=red];
  canceled [label="canceled",shape=circle,color=red];
  rejected [label="rejected",shape=box];
  reviewing [label="reviewing",shape=box];
  draft -> draft [label="modify1"];
  draft -> canceled [label="cancel1"];
  draft -> reviewing [label="submit_draft"];
  rejected -> rejected [label="modify2"];
  rejected -> canceled [label="cancel2"];
  rejected -> reviewing [label="submit2"];
  reviewing -> rejected [label="reject"];
  reviewing -> reviewed [label="agree"];
}
// custom_mark
```
</details>
