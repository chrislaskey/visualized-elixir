defmodule SolarWeb.SupervisorsLive.Supervisor do
  use Supervisor

  # Children

  def start_child(supervisor, child) do
    Supervisor.start_child(supervisor, child)
  end

  def count_children(supervisor) do
    Supervisor.count_children(supervisor)
  end

  def which_children(supervisor) do
    Supervisor.which_children(supervisor)
  end

  def terminate_child(supervisor, pid) do
    Supervisor.terminate_child(supervisor, pid)
  end

  # Supervisor

  def child_spec(opts \\ []) do
    # Supervisor uses the `id` to prevent duplicates. By default
    # the built-in child_spec function sets the ID to the module name.
    # This prevents us from creating multiple Supervisor children with
    # the same ID. The fix is to define our own `child_spec` function and
    # set the `id` to the `name` value instead.
    name = Keyword.fetch!(opts, :name)

    %{
      id: name,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    update_processes_agent_with_latest_structure()

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def update_processes_agent_with_latest_structure do
    data = SolarWeb.SupervisorsLive.Agent.Data.get()
    :ok = SolarWeb.SupervisorsLive.Processes.parse_and_store_child_processes(data)
  end

  @doc """
  This module is used for both the top-level supervisor AND and child supervisor nodes
  added to the ReactFlow visualization. It has a slightly more complex init process because
  the different callers will have different amounts of data to pass in.

  For child supervisor nodes, all the data will be passed in through `opts` from data
  that's stored in the Processes agent.

  The top-level supervisor will only have `:name` and `:strategy` defined in
  `application.ex` that gets passed in. It still needs to lookup the children
  from the Processes agent, which is situationally loaded using `get_lazy`.
  """
  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    strategy = Keyword.fetch!(opts, :strategy)
    children = Keyword.get_lazy(opts, :children, fn -> get_children_from_agent(name) end)

    SolarWeb.SupervisorsLive.Presence.track_pid(self(), name, %{status: "starting"})
    SolarWeb.SupervisorsLive.Presence.update_pid(self(), name, %{status: "running"}, after: 500)

    Supervisor.init(children, strategy: strategy)
  end

  def get_children_from_agent(name) do
    SolarWeb.SupervisorsLive.Agent.Processes.get_children(name)
  end
end
