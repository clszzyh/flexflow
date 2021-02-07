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
  @vsn "1.0.1"
  use Flexflow.Process

  defmodule Reviewing do
    use Flexflow.State
  end

  defmodule Submit do
    use Flexflow.Event
  end

  ## Start state
  state {Start, :draft}
  state {End, :reviewed}
  state {End, :canceled}
  ## Bypass state
  state :rejected
  ## Custom state
  state Reviewing

  ## Define a event
  ## `a ~> b` is a shortcut of `{a, b}`
  event :modify1, :draft ~> :draft
  event :cancel1, :draft ~> :canceled

  ## Custom event
  event Submit, :draft ~> Reviewing

  event :modify2, :rejected ~> :rejected
  event :cancel2, :rejected ~> :canceled

  ## With custom name
  event {Submit, :submit2}, :rejected ~> Reviewing

  event :reject, Reviewing ~> :rejected
  event :agree, Reviewing ~> :reviewed
end
```

<!-- MDOC -->

## Graphviz Dot

<details>
<summary><img src="https://g.gravizo.com/source/review_mark?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md"></summary>

```dot
// review_mark
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
// review_mark
```
</details>


## TODO

1. Support `:gen_statem`

```
State(S) x Event(E) -> Actions(A), State(S')
```

## See also

* https://erlang.org/doc/design_principles/statem.html
* https://en.wikipedia.org/wiki/Business_Process_Model_and_Notation
