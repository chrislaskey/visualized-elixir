defmodule SolarWeb.SupervisorsLive.Agent.Processes do
  @moduledoc """
  Stores process information.

  ## Supervisor Children

  A Supervisor can be configured at runtime. However, any data sent after the
  initial `init` will be lost if the process is restarted. This agent stores
  the `init` data so on restart the previous state can be used.
  """
  use Agent

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :state, %{})
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def clear_all_children() do
    Agent.update(__MODULE__, fn state ->
      Map.new(state, fn {key, value} ->
        {key, Map.put(value, :children, [])}
      end)
    end)
  end

  def get_children(key) do
    Agent.get(__MODULE__, fn state ->
      state
      |> Map.get(key, %{})
      |> Map.get(:children, [])
    end)
  end

  def set_children(key, value) do
    Agent.get_and_update(__MODULE__, fn state ->
      updated =
        Map.update(state, key, %{children: value}, fn current ->
          Map.merge(current, %{children: value})
        end)

      {{:ok, updated}, updated}
    end)
  end
end
