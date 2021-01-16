defmodule Flexflow do
  @external_resource readme = Path.join([__DIR__, "../README.md"])
  @moduledoc readme |> File.read!() |> String.split("<!-- MDOC -->") |> Enum.fetch!(1)

  @version Mix.Project.config()[:version]
  def version, do: @version

  @type name :: atom()
  @type id :: atom()

  @type event_key :: event_key_normalize | module()
  @type event_key_normalize :: {module(), id()}
end
