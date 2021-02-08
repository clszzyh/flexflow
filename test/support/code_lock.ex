defmodule CodeLock do
  @moduledoc false

  defmodule Locked do
    @moduledoc false

    use Flexflow.State
  end

  defmodule Open do
    @moduledoc false

    use Flexflow.State
  end

  # defmodule Door do
  #   @moduledoc false
  #   use Flexflow.Process
  #   state :locked
  #   state :open
  #   event :unlock, :locked ~> :open do
  #   end
  #   @impl true
  #   def init(%{__args__: %{code: code}} = p) do
  #     {:ok, %{p | context: %{code: code}}}
  #   end
  #   def init(_), do: {:error, "Need a code"}
  # end
end
