defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.History
  # alias Flexflow.Process
  alias Flexflow.ProcessManager
  alias Flexflow.ProcessServer

  @type process_identity :: {module(), id()} | pid()
  @type process_args :: map()

  @type name :: atom()
  @type id :: String.t()

  @type identity_or_module :: identity | module()
  @type identity :: {module(), name()}

  defdelegate history(key), to: History, as: :get
  defdelegate pid(key), to: ProcessServer
  defdelegate start(key, args \\ %{}), to: ProcessManager, as: :server
  defdelegate state(key), to: ProcessManager
  defdelegate call(key, op), to: ProcessManager
  defdelegate cast(key, op), to: ProcessManager
end
