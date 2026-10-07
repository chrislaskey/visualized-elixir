defmodule SolarWeb.SupervisorsLive.DynamicSupervisor do
  use DynamicSupervisor

  # Children

  def start_child(supervisor, child) do
    DynamicSupervisor.start_child(supervisor, child)
  end

  def count_children(supervisor) do
    DynamicSupervisor.count_children(supervisor)
  end

  def which_children(supervisor) do
    DynamicSupervisor.which_children(supervisor)
  end

  def terminate_child(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  # Supervisor

  def start_link(opts \\ []) do
    name = Keyword.fetch!(opts, :name)

    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    strategy = Keyword.fetch!(opts, :strategy)

    DynamicSupervisor.init(strategy: strategy)
  end
end
