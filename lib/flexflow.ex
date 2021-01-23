defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.Event
  # alias Flexflow.Process
  alias Flexflow.ProcessManager
  alias Flexflow.Transition

  @type process_identity :: {module(), id()}
  @type process_args :: map()

  @type name :: String.t()
  @type id :: String.t()

  @type key :: key_normalize | module()
  @type key_normalize :: {module(), name()}

  @type events :: %{key_normalize() => Event.t()}
  @type transitions :: %{key_normalize() => Transition.t()}

  defdelegate start(key, args \\ %{}), to: ProcessManager, as: :server
  defdelegate state(key), to: ProcessManager
  defdelegate call(key, op), to: ProcessManager
  defdelegate cast(key, op), to: ProcessManager
end
