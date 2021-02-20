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
      IO.puts("[#{p.id}] locked...")
      {:ok, p}
    end

    @impl true
    ## Match
    def handle_input(
          :cast,
          {:button, button},
          %{context: %{code: code, buttons: buttons}} = state,
          _p
        )
        when is_binary(code) and byte_size(button) == 1 and code == [button | buttons] do
      {:ok, clear_button(state), {:custom, :correct}}
    end

    ## Not match
    def handle_input(:cast, {:button, button}, %{context: %{buttons: buttons}} = state, _p)
        when is_binary(button) and byte_size(button) == 1 and length(buttons) == @code_length - 1 do
      {:ok, clear_button(state), {:custom, :incorrect}}
    end

    ## Collect
    def handle_input(:cast, {:button, button}, %{context: %{buttons: buttons} = ctx} = state, _p)
        when is_binary(button) and byte_size(button) == 1 and length(buttons) < @code_length - 1 do
      {:ok, %{state | context: %{ctx | buttons: [button | buttons]}}}
    end

    def handle_input(type, input, _, _), do: {:error, "Invalid input: #{inspect(type, input)}"}

    defp clear_button(%Event{context: %{} = context} = e) do
      %{e | context: %{context | buttons: []}}
    end
  end

  defmodule Opened do
    @moduledoc false

    use Flexflow.State

    @impl true
    def handle_enter(_e, p) do
      IO.puts("[#{p.id}] unlocked...")
      {:ok, p}
    end
  end

  defmodule Button do
    @moduledoc false
    use Flexflow.Event

    @impl true
    def is_event(button), do: is_binary(button) and byte_size(button) == 1
  end

  defmodule Door do
    @moduledoc false
    use Flexflow.Process

    state Locked, type: :start
    state Opened

    event Button, Locked ~> Locked
    event Button, Locked ~> Opened

    event Button, Opened ~> Opened do
      @impl true
      def handle_event(:cast, _button, _state, _p), do: :ignore
    end
  end
end
