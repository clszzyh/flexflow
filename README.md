# Flexflow

[![ci](https://github.com/clszzyh/flexflow/workflows/ci/badge.svg)](https://github.com/clszzyh/flexflow/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/flexflow)](http://hex.pm/packages/flexflow)
[![Hex.pm](https://img.shields.io/hexpm/dt/flexflow)](http://hex.pm/packages/flexflow)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/flexflow/readme.html)
[![Last Updated](https://img.shields.io/github/last-commit/clszzyh/flexflow.svg)](https://github.com/clszzyh/flexflow/commits/master)

<!-- MDOC -->

## Usage

```elixir
defmodule Verify do
  @moduledoc false

  defmodule Uncertified do
    use Flexflow.Node
  end

  defmodule Certified do
    use Flexflow.Node
  end

  defmodule Rejected do
    use Flexflow.Node
  end

  defmodule Canceled do
    use Flexflow.Node
  end

  defmodule Cert do
    use Flexflow.Transition
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Modify do
    use Flexflow.Transition
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Reject do
    use Flexflow.Transition
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Cancel do
    use Flexflow.Transition
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  use Flexflow.Process, version: 1

  start_node Uncertified
  end_node Certified
  intermediate_node Rejected
  end_node Canceled

  transition Cert, Uncertified ~> Certified
  transition Modify, Uncertified ~> Uncertified
  transition Reject, Uncertified ~> Rejected
  transition Cancel, Uncertified ~> Canceled
  transition Modify, Rejected ~> Uncertified
  transition Cancel, Rejected ~> Canceled
end
```

<!-- MDOC -->

## Dot

<details>
<summary><img src="https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md" width="50%"></summary>

```dot
// custom_mark10
digraph verify {
  size = "4,4";
  uncertified [label=uncertified,shape=doublecircle,color=".7 .3 1.0"];
  certified [label=certified,shape=circle,color=red];
  rejected [label=rejected,shape=box];
  canceled [label=canceled,shape=circle,color=red];
  uncertified -> certified [label=cert];
  uncertified -> uncertified [label=modify,color=blue];
  uncertified -> rejected [label=reject];
  uncertified -> canceled [label=cancel];
  rejected -> uncertified [label=modify];
  rejected -> canceled [label=cancel];
}
// custom_mark10
```
</details>


## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
