defmodule Flexflow.ProcessLoader do
  @moduledoc """
  YamlLoader
  """

  @process_app Application.compile_env(:flexflow, :process_app, :flexflow)
  @process_path Application.app_dir(@process_app, "priv/processes/*.yml")

  @processes Path.wildcard(@process_path)

  alias Flexflow.Util

  for path <- @processes do
    @external_resource path
  end

  def __mix_recompile__? do
    :erlang.md5(Path.wildcard(@process_path)) != unquote(:erlang.md5(@processes))
  end

  def parse(path) do
    [body] = :yamerl_constr.file(path, [:str_node_as_binary])
    compile(Map.new(body), path)
  end

  defp compile(%{"name" => name, "version" => version} = raw, path) do
    module_name = Module.concat(Flexflow.Processes, Macro.camelize(name))
    IO.puts("define #{module_name}")

    if Util.defined?(module_name) do
      :code.purge(module_name)
      :code.delete(module_name)
    end

    ast =
      quote do
        @vsn unquote(version)
        def __raw__, do: unquote(Macro.escape(raw))

        use Flexflow.Process

        activity Flexflow.Activities.Start
        activity Flexflow.Activities.End

        gateway :first, Flexflow.Activities.Start ~> Flexflow.Activities.End
      end

    {:module, final_module, _byte_code, _} = Module.create(module_name, ast, file: path, line: 0)

    final_module
  end

  defp compile(_body, path), do: raise(ArgumentError, "#{path} is invalid")

  @after_compile __MODULE__
  def __after_compile__(_env, _bytecode) do
    Enum.each(@processes, &parse/1)
  end
end
