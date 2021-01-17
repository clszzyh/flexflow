defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  alias Flexflow.Node
  alias Flexflow.Transition

  @type name :: atom()
  @type id :: atom()

  @type key :: key_normalize | module()
  @type key_normalize :: {module(), id()}

  @type nodes :: %{key_normalize() => Node.t()}
  @type transitions :: %{key_normalize() => Transition.t()}
end
