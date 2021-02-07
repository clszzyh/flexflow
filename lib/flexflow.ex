defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.History
  # alias Flexflow.Process
  alias Flexflow.ProcessManager
  alias Flexflow.ProcessStatem

  @type process_key :: {module(), id()}
  @type process_identity :: process_key | pid()
  @type process_args :: map()

  @type name :: atom()
  @type id :: String.t()

  @type state_type_or_module :: state_type | module()
  @type state_type :: {module(), name()}
  @type state_key :: name()

  defdelegate server(key, args \\ %{}), to: ProcessManager
  defdelegate start(key, args \\ %{}), to: ProcessManager, as: :start_child
  defdelegate stop(srv \\ nil, key), to: ProcessManager, as: :stop_child
  defdelegate history(key), to: History, as: :get
  defdelegate pid(key), to: ProcessStatem
  defdelegate state(key), to: ProcessStatem
  # defdelegate start_child(key, child_key, args \\ %{}), to: ProcessServer
  defdelegate call(key, op), to: ProcessStatem
  defdelegate cast(key, op), to: ProcessStatem
end
