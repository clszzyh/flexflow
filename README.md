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

  start_node Draft
  end_node Canceled
  end_node Reviewed
  intermediate_node Rejected
  intermediate_node Inreview

  transition Submit, Draft ~> Inreview
  transition Modify, Draft ~> Draft
  transition Cancel, Draft ~> Canceled

  transition Submit, Rejected ~> Inreview
  transition Modify, Rejected ~> Rejected
  transition Cancel, Rejected ~> Canceled

  transition Agree, Inreview ~> Reviewed
  transition Reject, Inreview ~> Rejected
end
```

<!-- MDOC -->

## Graphviz Dot

<details>
<summary><img src="https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md" width="50%"></summary>

```dot
// custom_mark10
digraph review {
  size = "4,4";
  draft [label=draft,shape=doublecircle,color=".7 .3 1.0"];
  canceled [label=canceled,shape=circle,color=red];
  reviewed [label=reviewed,shape=circle,color=red];
  rejected [label=rejected,shape=box];
  inreview [label=inreview,shape=box];
  draft -> inreview [label=submit];
  draft -> draft [label=modify,color=blue];
  draft -> canceled [label=cancel];
  rejected -> inreview [label=submit];
  rejected -> rejected [label=modify,color=blue];
  rejected -> canceled [label=cancel];
  inreview -> reviewed [label=agree];
  inreview -> rejected [label=reject];
}
// custom_mark10
```
</details>


## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
