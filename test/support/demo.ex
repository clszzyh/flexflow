for i <- 1..10 do
  defmodule String.to_atom("Elixir.N#{i}") do
    @moduledoc false
    use Flexflow.Event
  end

  defmodule String.to_atom("Elixir.T#{i}") do
    @moduledoc false
    use Flexflow.Transition
  end
end

defmodule P1 do
  @moduledoc false
  use Flexflow.Process, hello: %{foo: :zzzz}

  @impl true
  def name, do: "p1_new"

  event N1, kind: :start, foo: %{aaa: :bbb}
  event N2

  transition T1, N1 ~> N2, foo: :baz

  event N3, async: true
  event N4, kind: :end

  transition T2, N2 ~> N3
  transition {T2, "1"}, N2 ~> N4
end

defmodule P2 do
  @moduledoc false

  defmodule Slow do
    @moduledoc false
    use Flexflow.Event

    @impl true
    def before_change({:created, [:initial]}, event, %{__args__: %{slow: strategy}}) do
      Process.sleep(50)

      case strategy do
        :ok -> {:ok, event}
        :error -> {:error, :custom_error}
        :other -> {:ok, :other}
        :raise -> raise("fooo")
      end
    end

    def before_change(_, o, _), do: {:ok, o}
  end

  use Flexflow.Process

  event Start
  event End
  event Slow, async: true

  transition "first", Start ~> Slow
  transition "last", Slow ~> End
end
