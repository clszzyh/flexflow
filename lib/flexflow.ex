defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.Node
  alias Flexflow.Transition

  @type process_identity :: {module(), id()}
  @type process_args :: map()

  @type node_opts :: keyword()

  @type name :: String.t()
  @type id :: String.t()

  @type key :: key_normalize | module()
  @type key_normalize :: {module(), name()}

  @type nodes :: %{key_normalize() => Node.t()}
  @type transitions :: %{key_normalize() => Transition.t()}
end
