defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.History
  # alias Flexflow.Process
  alias Flexflow.ProcessManager
  alias Flexflow.ProcessServer

  @type process_key :: {module(), id()}
  @type process_identity :: process_key | pid()
  @type process_args :: map()

  @type name :: atom()
  @type id :: String.t()

  @type identity_or_module :: identity | module()
  @type identity :: {module(), name()}

  defdelegate history(key), to: History, as: :get
  defdelegate pid(key), to: ProcessServer
  defdelegate start(key, args \\ %{}), to: ProcessManager, as: :server
  defdelegate state(key), to: ProcessServer
  defdelegate start_child(key, child_key, args \\ %{}), to: ProcessServer
  defdelegate call(key, op), to: ProcessServer
  defdelegate cast(key, op), to: ProcessServer
end
