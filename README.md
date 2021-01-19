# Flexflow

[![ci](https://github.com/clszzyh/flexflow/workflows/ci/badge.svg)](https://github.com/clszzyh/flexflow/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/flexflow)](http://hex.pm/packages/flexflow)
[![Hex.pm](https://img.shields.io/hexpm/dt/flexflow)](http://hex.pm/packages/flexflow)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/flexflow/readme.html)


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

  defnode Uncertified
  defnode Certified
  defnode Rejected
  defnode Canceled

  deftransition Cert, {Uncertified, Certified}
  deftransition Modify, {Uncertified, Uncertified}
  deftransition Reject, {Uncertified, Rejected}
  deftransition Cancel, {Uncertified, Canceled}
  deftransition Modify, {Rejected, Uncertified}
  deftransition Cancel, {Canceled, Uncertified}
end
```

<!-- MDOC -->


![Alt text](https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fclszzyh%2Fflexflow%2Fmaster%2FREADME.md)
<details>
<summary></summary>

```
custom_mark10
  digraph G {
    size ="4,4";
    main [shape=box];
    main -> parse [weight=8];
    parse -> execute;
    main -> init [style=dotted];
    main -> cleanup;
    execute -> { make_string; printf};
    init -> make_string;
    edge [color=red];
    main -> printf [style=bold,label="100 times"];
    make_string [label="make a string"];
    node [shape=box,style=filled,color=".7 .3 1.0"];
    execute -> compare;
  }
custom_mark10
```
</details>





## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
