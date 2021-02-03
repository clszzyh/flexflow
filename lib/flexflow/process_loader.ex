defmodule Flexflow.ProcessLoader do
  @moduledoc """
  YamlLoader
  """

  @process_app Application.compile_env(:flexflow, :process_app, :flexflow)
  @process_path Application.app_dir(@process_app, "priv/processes/*.yml")

  @processes Path.wildcard(@process_path)

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

  defp compile(%{"name" => name}, path) do
    module_name = Module.concat(Flexflow.Processes, name)
    IO.puts("define #{module_name}")
    {:ok, path}
  end

  defp compile(_body, path), do: {:error, "#{path} is invalid"}

  @after_compile __MODULE__
  def __after_compile__(_env, _bytecode) do
    for p <- @processes do
      case parse(p) do
        {:ok, _} -> :ok
        {:error, reason} -> raise ArgumentError, reason
      end
    end
  end
end
