defmodule Flexflow.Api do
  @moduledoc """
  Api
  """

  alias Flexflow.Config
  alias Flexflow.Node
  alias Flexflow.Process
  alias Flexflow.Telemetry
  alias Flexflow.Transition

  @spec start(module(), Flexflow.id(), Flexflow.process_args()) :: Process.result()
  def start(module, id, args \\ %{}) do
    p = module.new(id, args)

    {:ok, p}
    |> telemetry_invoke(:process_init, &init/1)
    |> telemetry_invoke(:process_loop, &loop/1)
  end

  @spec call(Process.t(), term(), GenServer.from() | nil) :: Process.handle_call_return()
  def call(%Process{} = p, input, from \\ nil) do
    {:stop, {:call, input, from}, p}
  end

  @spec cast(Process.t(), term()) :: Process.handle_cast_return()
  def cast(%Process{} = p, input) do
    {:stop, {:cast, input}, p}
  end

  @spec info(Process.t(), term()) :: Process.handle_info_return()
  def info(%Process{} = p, input) do
    {:stop, {:info, input}, p}
  end

  @spec terminate(Process.t(), term()) :: term()
  def terminate(%Process{} = _p, _reason) do
    :ok
  end

  @spec init(Process.t()) :: Process.result()
  def init(%Process{module: module, nodes: nodes, transitions: transitions} = p) do
    (Map.to_list(nodes) ++ Map.to_list(transitions))
    |> Enum.reduce_while(p, fn {key, %{module: module} = o}, p ->
      case module.init(o, p) do
        {:ok, %Node{} = node} ->
          {:cont, put_in(p, [:nodes, key], %{node | state: :initial})}

        {:ok, %Transition{} = transition} ->
          {:cont, put_in(p, [:transitions, key], %{transition | state: :initial})}

        {:error, reason} ->
          {:halt, {key, reason}}
      end
    end)
    |> module.init()
    |> case do
      {:error, reason} -> {:error, reason}
      {:ok, %Process{} = p} -> {:ok, %{p | state: :active}}
    end
  end

  @max_loop_limit Config.get(:max_loop_limit)

  @spec loop(Process.t()) :: Process.result()
  def loop(%{state: state} = p) when state in [:active],
    do: loop(%{p | state: :loop, __loop_counter__: 0})

  def loop(%{state: :loop, __loop_counter__: 50} = p), do: {:ok, %{p | state: :active}}

  def loop(%{state: :loop} = p) do
    case next(p) do
      {:error, reason} -> {:error, reason}
      {:ok, p} -> loop(p)
    end
  end

  @spec next(Process.t()) :: Process.result()
  def next(%{__loop_counter__: loop_counter}) when loop_counter > @max_loop_limit,
    do: {:error, :exceed_loop_limit}

  def next(%{__loop_counter__: loop_counter, __counter__: counter} = p) do
    {:ok, %{p | __loop_counter__: loop_counter + 1, __counter__: counter + 1}}
  end

  @spec telemetry_invoke(Process.result(), atom(), (Process.t() -> Process.result())) ::
          Process.result()
  def telemetry_invoke({:error, reason}, _, _), do: {:error, reason}

  def telemetry_invoke({:ok, p}, name, f) do
    Telemetry.span(
      name,
      fn ->
        {state, result} = f.(p)
        {{state, result}, %{state: state}}
      end,
      %{id: p.id}
    )
  end
end
