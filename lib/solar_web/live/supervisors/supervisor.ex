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

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    strategy = Keyword.fetch!(opts, :strategy)
    name = Keyword.fetch!(opts, :name)

    children =
      Keyword.get(opts, :children, SolarWeb.SupervisorsLive.Agent.Processes.get_children(name))

    {:ok, _} = SolarWeb.SupervisorsLive.Agent.Processes.set_children(name, children)

    Supervisor.init(children, strategy: strategy)
  end
end
