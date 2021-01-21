defmodule Flexflow.ProcessSupervisor do
  @moduledoc """
  ProcessSupervisor
  """

  use Flexflow.ProcessRegistry
  use Supervisor

  def start_link(module, {id, opts}) do
    Supervisor.start_link(__MODULE__, {module, id, opts}, name: via_tuple({module, id}))
  end

  @impl true
  def init({module, id, opts}) do
    process = module.new(id)

    node_children =
      for {_, node} <- process.nodes, node.__opts__[:async] == true do
        {Flexflow.NodeServer, {module, id, node.module, node.name}}
      end

    transition_children =
      for {_, transition} <- process.transitions, transition.__opts__[:async] == true do
        {Flexflow.TransitionServer, {module, id, transition.module, transition.name}}
      end

    Supervisor.init(
      [{Flexflow.ProcessServer, {module, id, opts}}] ++ node_children ++ transition_children,
      strategy: :one_for_one
    )
  end
end
