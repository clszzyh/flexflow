# Flexflow

[![ci](https://github.com/clszzyh/flexflow/workflows/ci/badge.svg)](https://github.com/clszzyh/flexflow/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/flexflow)](http://hex.pm/packages/flexflow)
[![Hex.pm](https://img.shields.io/hexpm/dt/flexflow)](http://hex.pm/packages/flexflow)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/flexflow/readme.html)
[![Last Updated](https://img.shields.io/github/last-commit/clszzyh/flexflow.svg)](https://github.com/clszzyh/flexflow/commits/master)

<!-- MDOC -->

## Usage

```elixir
defmodule Review do
  @moduledoc false

  defmodule Draft do
    use Flexflow.Node
  end

  defmodule Inreview do
    use Flexflow.Node
  end

  defmodule Reviewed do
    use Flexflow.Node
  end

  defmodule Rejected do
    use Flexflow.Node
  end

  defmodule Canceled do
    use Flexflow.Node
  end

  defmodule Submit do
    use Flexflow.Transition
  end

  defmodule Agree do
    use Flexflow.Transition
  end

  defmodule Modify do
    use Flexflow.Transition
  end

  defmodule Reject do
    use Flexflow.Transition
  end

  defmodule Cancel do
    use Flexflow.Transition
  end

  use Flexflow.Process, version: 1

  ## Define a start node
  start_node Draft
  ## Define an end node
  end_node Canceled
  end_node {Reviewed, "Already reviewed"}
  ## Define an intermediate node
  intermediate_node Inreview
  intermediate_node Rejected

  ## Define a transition
  ## `a ~> b` is a shortcut of `{a, b}`
  transition Submit, Draft ~> Inreview
  transition Modify, Draft ~> Draft
  transition Cancel, Draft ~> Canceled

  transition Submit, Rejected ~> Inreview
  transition Modify, Rejected ~> Rejected
  transition Cancel, Rejected ~> Canceled

  ## Define a transition
  transition Reject, Inreview ~> Rejected
  transition Agree, Inreview ~> {Reviewed, "Already reviewed"}
end
```

<!-- MDOC -->

## Graphviz Dot

<details>
<summary><img src="https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md" width="100%"></summary>

```dot
// custom_mark10
digraph review {
  size = "4,4";
  "draft" [label="draft",shape=doublecircle,color=".7 .3 1.0"];
  "canceled" [label="canceled",shape=circle,color=red];
  "Already reviewed" [label="Already reviewed",shape=circle,color=red];
  "inreview" [label="inreview",shape=box];
  "rejected" [label="rejected",shape=box];
  "draft" -> "inreview" [label="submit"];
  "draft" -> "draft" [label="modify",color=blue];
  "draft" -> "canceled" [label="cancel"];
  "rejected" -> "inreview" [label="submit"];
  "rejected" -> "rejected" [label="modify",color=blue];
  "rejected" -> "canceled" [label="cancel"];
  "inreview" -> "rejected" [label="reject"];
  "inreview" -> "Already reviewed" [label="agree"];
}
// custom_mark10
```
</details>


## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
