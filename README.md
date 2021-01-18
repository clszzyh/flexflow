# Flexflow

[![ci](https://github.com/clszzyh/flexflow/workflows/ci/badge.svg)](https://github.com/clszzyh/flexflow/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/flexflow)](http://hex.pm/packages/flexflow)
[![Hex.pm](https://img.shields.io/hexpm/dt/flexflow)](http://hex.pm/packages/flexflow)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/flexflow/readme.html)


<!-- MDOC -->

## Usage

```elixir
defmodule Flexflow.Processes.Basic do
  use Flexflow.Process

  defnode Nodes.Start
  defnode Nodes.End

  deftransition Transitions.Pass, {Nodes.Start, Nodes.End}

  @impl true
  def name, do: :basic
end
```

<!-- MDOC -->

## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
