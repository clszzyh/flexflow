defmodule CodeLock do
  @moduledoc """
  ## See also

  * https://erlang.org/doc/design_principles/statem.html#example
  """

  defmodule Locked do
    @moduledoc false

    use Flexflow.State

    @code_length 6

    @impl true
    def init(e, %{__args__: %{code: code}})
        when is_binary(code) and byte_size(code) == @code_length do
      {:ok, %{e | context: %{code: Enum.reverse(for(<<i <- code>>, do: <<i>>)), buttons: []}}}
    end

    def init(_, _), do: {:error, "Need a #{@code_length}-length code"}

    @impl true
    def handle_enter(_e, p) do
      Logger.debug("[#{p.id}] enter locked...")
      {:ok, p}
    end

    @impl true
    def handle_leave(_e, p) do
      Logger.debug("[#{p.id}] leave locked...")
      {:ok, p}
    end
  end

  defmodule Opened do
    @moduledoc false

    use Flexflow.State

    @impl true
    def handle_enter(_e, p) do
      Logger.debug("[#{p.id}] enter unlocked...")
      {:ok, p}
    end

    @impl true
    def handle_leave(_e, p) do
      Logger.debug("[#{p.id}] leave unlocked...")
      {:ok, p}
    end
  end

  defmodule Button do
    @moduledoc false
    use Flexflow.Event

    @impl true
    def is_event(button), do: is_binary(button) and byte_size(button) == 1

    @impl true
    def handle_input(_, %State{name: :opened}, _), do: {:ok, :ignore}

    def handle_input(button, %State{name: :locked, context: %{code: code, buttons: buttons}}, _p)
        when code == [button | buttons],
        do: {:ok, :correct}

    def handle_input(_, %State{name: :locked, context: %{code: code, buttons: buttons}}, _p)
        when length(buttons) == length(code) - 1,
        do: {:ok, :incorrect}

    def handle_input(_, %State{name: :locked}, _p), do: {:ok, :collect}

    def clear_buttons(%State{context: %{} = context} = state) do
      %{state | context: %{context | buttons: []}}
    end

    def collect_button(%State{context: %{buttons: buttons} = context} = state, button) do
      %{state | context: %{context | buttons: [button | buttons]}}
    end
  end

  defmodule Door do
    @moduledoc false
    use Flexflow.Process

    state Locked, type: :start
    state Opened

    event Button, Locked ~> Opened, results: [:correct] do
      @impl true
      def handle_result(:correct, :cast, _, state, _p) do
        {:ok, Button.clear_buttons(state), [{:state_timeout, 100, :ignore}]}
      end
    end

    event Button, Locked ~> Locked, results: [:incorrect, :collect] do
      @impl true
      def handle_result(:incorrect, :cast, _, state, _p) do
        {:ok, Button.clear_buttons(state)}
      end

      def handle_result(:collect, :cast, button, state, _p) do
        {:ok, Button.collect_button(state, button)}
      end
    end

    event Button, Opened ~> Opened

    event StateTimeout, Opened ~> Locked
  end
end
