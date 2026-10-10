defmodule SolarWeb.SupervisorsLive.Supervisor do
  use Supervisor

  @root_process_name :"SolarWeb.SupervisorsLive.Supervisor"
  @child_definition {SolarWeb.SupervisorsLive.Supervisor,
                     name: @root_process_name, strategy: :one_for_one, type: "supervisor"}

  def child_definition, do: @child_definition
  def root_process_name, do: @root_process_name

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

  def restart_child(supervisor, pid) do
    Supervisor.restart_child(supervisor, pid)
  end

  # Supervisor

  def child_spec(opts \\ []) do
    # Supervisor uses the `id` to prevent duplicates. By default
    # the built-in child_spec function sets the ID to the module name.
    # This prevents us from creating multiple Supervisor children with
    # the same ID. The fix is to define our own `child_spec` function and
    # set the `id` to the `name` value instead.
    name = Keyword.fetch!(opts, :name)
    restart = Keyword.get(opts, :restart, :permanent)

    %{
      id: name,
      restart: restart,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    strategy = Keyword.fetch!(opts, :strategy)

    children = SolarWeb.SupervisorsLive.Agent.Processes.get_children(name)
    process = Keyword.put(opts, :children, children)

    SolarWeb.SupervisorsLive.Agent.Processes.merge(name, process)
    SolarWeb.SupervisorsLive.Presence.track_pid(self(), name, presence(%{status: "starting"}))
    SolarWeb.SupervisorsLive.Presence.update_pid(self(), name, presence(%{status: "running"}), after: 500)

    Supervisor.init(children, strategy: strategy)
  end

  def presence(additional \\ %{}) do
    base = %{pid: inspect(self())}

    Map.merge(base, additional)
  end
end
