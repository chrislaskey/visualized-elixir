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

  def get_children(key) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, key, [])
    end)
  end

  def set_children(key, value) do
    Agent.get_and_update(__MODULE__, fn state ->
      updated = Map.put_new(state, key, %{key => value})

      {{:ok, updated}, updated}
    end)
  end
end
