defmodule FlexflowDemoTest do
  @moduledoc false

  for i <- 1..9 do
    defmodule String.to_atom("#{__MODULE__}.N#{i}") do
      @moduledoc false
      use Flexflow.Event
    end

    defmodule String.to_atom("#{__MODULE__}.T#{i}") do
      @moduledoc false
      use Flexflow.Gateway
    end
  end

  defmodule P1 do
    @moduledoc false
    use Flexflow.Process, hello: %{foo: :zzzz}

    alias FlexflowDemoTest.{N1, N2, N3, N4}
    alias FlexflowDemoTest.{T1, T2}

    @impl true
    def name, do: :p1_new

    event N1, kind: :start, foo: %{aaa: :bbb}
    event N2

    gateway T1, N1 ~> N2, foo: :baz

    event N3, async: true
    event N4, kind: :end

    gateway T2, N2 ~> N3
    gateway {T2, :t2_name}, N2 ~> N4
  end

  defmodule P2 do
    @moduledoc false

    defmodule Slow do
      @moduledoc false
      use Flexflow.Event

      @impl true
      def before_change({:created, :initial}, event, %{__args__: %{slow: strategy, sleep: sleep}}) do
        Process.sleep(sleep)

        case strategy do
          :ok -> {:ok, event}
          :error -> {:error, :custom_error}
          :other -> {:ok, :other}
          :raise -> raise("fooo")
        end
      end

      def before_change(o, _, %{__args__: args}), do: raise(inspect({:not_supported, o, args}))
    end

    use Flexflow.Process

    event Start
    event End
    event Slow, async: [timeout: 5000]

    gateway :first, Start ~> Slow
    gateway :last, Slow ~> End
  end
end
