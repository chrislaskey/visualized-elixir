defmodule SolarWeb.SupervisorsLive.Agent.Processes do
  @moduledoc """
  Stores process information.

  ## Supervisor Children

  A Supervisor can be configured at runtime. However, any data sent after the
  initial `init` will be lost if the process is restarted. This agent stores
  the `init` data so on restart the previous state can be used.

  When the UI changes the process structure, the existing data is replaced
  with the new expected state. Which then the process context uses to rebuild
  the correct process state.
  """
  use Agent

  def start_link(opts \\ []) do
    initial_state = Keyword.get_lazy(opts, :state, &parse_data_agent_state/0)

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def parse_data_agent_state do
    data = SolarWeb.SupervisorsLive.Agent.Data.get()

    SolarWeb.SupervisorsLive.Processes.parse_child_processes(data)
  end

  # Functions

  def get do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, key)
    end)
  end

  def set(key, value) do
    Agent.get_and_update(__MODULE__, fn state ->
      updated = Map.put(state, key, value)

      {updated, updated}
    end)
  end

  def merge(key, value) do
    Agent.get_and_update(__MODULE__, fn state ->
      updated =
        Map.update(state, key, value, fn current ->
          Keyword.merge(current, value)
        end)

      {updated, updated}
    end)
  end

  def clear_all() do
    Agent.update(__MODULE__, fn _state -> %{} end)
  end

  # Functions - children

  def get_children(key) do
    Agent.get(__MODULE__, fn state ->
      state
      |> Map.get(key, [])
      |> Keyword.get(:children, [])
    end)
  end

  def set_children(key, value) do
    Agent.get_and_update(__MODULE__, fn state ->
      updated =
        Map.update(state, key, [children: value], fn current ->
          Keyword.merge(current, children: value)
        end)

      {updated, updated}
    end)
  end
end
