defmodule FlexflowDemoTest do
  @moduledoc false

  for i <- 1..9 do
    defmodule String.to_atom("#{__MODULE__}.N#{i}") do
      @moduledoc false
      use Flexflow.State

      @impl true
      def type, do: :bypass
    end

    defmodule String.to_atom("#{__MODULE__}.T#{i}") do
      @moduledoc false
      use Flexflow.Event
    end
  end

  defmodule P1 do
    @moduledoc false
    use Flexflow.Process, hello: %{foo: :zzzz}

    alias FlexflowDemoTest.{N1, N2, N3, N4}
    alias FlexflowDemoTest.{T1, T2}

    @impl true
    def name, do: :p1_new
    @impl true
    def terminate(p, reason) do
      IO.puts(inspect({:terminate, p.id, reason}))
    end

    state N1, type: :start, foo: %{aaa: :bbb}
    state N2

    event T1, N1 ~> N2, foo: :baz

    state N3, async: true
    state N4, type: :end

    event T2, N2 ~> N3
    event {T2, :t2_name}, N2 ~> N4
  end

  defmodule P2 do
    @moduledoc false

    defmodule Slow do
      @moduledoc false
      use Flexflow.State

      @impl true
      def type, do: :bypass
    end

    use Flexflow.Process

    state Start
    state End

    state {Slow, :slow1}, async: [timeout: 5000] do
      @impl true
      def validate(_, _) do
        IO.puts("state ok")
        :ok
      end
    end

    event :first, Start ~> :slow1, foo: :bar do
      @impl true
      def validate(_, _) do
        IO.puts("event ok")
        :ok
      end
    end

    event :last, :slow1 ~> End
  end
end
