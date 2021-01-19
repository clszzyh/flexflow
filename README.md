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
    @impl true
    def name, do: :uncertified
  end

  defmodule Certified do
    use Flexflow.Node
    @impl true
    def name, do: :certified
  end

  defmodule Rejected do
    use Flexflow.Node
    @impl true
    def name, do: :rejected
  end

  defmodule Canceled do
    use Flexflow.Node
    @impl true
    def name, do: :canceled
  end

  defmodule Cert do
    use Flexflow.Transition
    @impl true
    def name, do: :cert
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Modify do
    use Flexflow.Transition
    @impl true
    def name, do: :modify
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Reject do
    use Flexflow.Transition
    @impl true
    def name, do: :reject
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  defmodule Cancel do
    use Flexflow.Transition
    @impl true
    def name, do: :cancel
    @impl true
    def handle_enter(_, _, _), do: :pass
  end

  use Flexflow.Process, version: 1

  @impl true
  def name, do: :verify

  defnode Uncertified
  defnode Certified
  defnode Rejected
  defnode Canceled

  deftransition Cert, {Uncertified, Certified}
  deftransition Modify, {Uncertified, Uncertified}
  deftransition Reject, {Uncertified, Rejected}
  deftransition Cancel, {Uncertified, Canceled}
end
```

<!-- MDOC -->

## See Also

* [BPMN document](https://www.omg.org/spec/BPMN/2.0/PDF)
* [Activiti document](http://www.mossle.com/docs/activiti/index.html#bpmn20)
