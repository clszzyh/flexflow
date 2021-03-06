defmodule Flexflow.ProcessLoader do
  @moduledoc """
  YamlLoader
  """

  @current_app Mix.Project.config()[:app]
  @process_path Application.app_dir(@current_app, "priv/processes/*.yml")
  @processes Path.wildcard(@process_path)

  alias Flexflow.States.{Bypass, End, Start}, warn: false
  alias Flexflow.Util

  require Logger

  for path <- @processes do
    @external_resource path
  end

  def __mix_recompile__? do
    :erlang.md5(Path.wildcard(@process_path)) != unquote(:erlang.md5(@processes))
  end

  @blank_ast {:__block__, [], []}

  defp compile(%{"name" => name} = raw, path) do
    module_name = Module.concat(Flexflow.Processes, Macro.camelize(name))

    if Util.defined?(module_name) do
      :code.purge(module_name)
      :code.delete(module_name)
    end

    vsn_ast =
      case raw do
        %{"version" => version} -> quote(do: @vsn(unquote(to_string(version))))
        _ -> @blank_ast
      end

    ast =
      quote do
        unquote(vsn_ast)
        def __raw__, do: unquote(Macro.escape(raw))

        use Flexflow.Process

        state Start
        state End

        event :first, Start ~> End
      end

    {:module, ^module_name, _byte_code, _} = Module.create(module_name, ast, file: path, line: 0)

    Logger.debug("Create #{module_name} -> #{name}")

    module_name
  end

  defp compile(_body, path), do: raise(ArgumentError, "#{path} is invalid")

  @after_compile __MODULE__
  def __after_compile__(_env, _bytecode) do
    Enum.each(@processes, fn path ->
      [body] = :yamerl_constr.file(path, [:str_node_as_binary])
      compile(Map.new(body), path)
    end)
  end
end
