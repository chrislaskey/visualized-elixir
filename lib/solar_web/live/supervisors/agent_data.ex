defmodule SolarWeb.SupervisorsLive.Agent.Data do
  use Agent

  @default_data %{
    "nodes" => [
      %{
        "id" => "root",
        "type" => "supervisor",
        "position" => %{"x" => 180, "y" => 0},
        "data" => %{
          "label" => "Supervisor 1",
          "root" => true,
          "config" => %{"strategy" => "one_for_one"}
        }
      },
      %{
        "id" => "sup-2",
        "type" => "supervisor",
        "position" => %{"x" => 0, "y" => 240},
        "data" => %{
          "label" => "Supervisor 2",
          "config" => %{"strategy" => "one_for_all"}
        }
      },
      %{
        "id" => "gen-3",
        "type" => "worker",
        "position" => %{"x" => 360, "y" => 240},
        "data" => %{
          "label" => "GenServer 3",
          "config" => %{"restart" => "permanent"}
        }
      },
      %{
        "id" => "gen-4",
        "type" => "worker",
        "position" => %{"x" => 0, "y" => 500},
        "data" => %{
          "label" => "GenServer 4",
          "config" => %{"restart" => "permanent"}
        }
      }
    ],
    "edges" => [
      %{"id" => "root-sup-2", "source" => "root", "target" => "sup-2"},
      %{"id" => "root-gen-3", "source" => "root", "target" => "gen-3"},
      %{"id" => "sup-2-gen-4", "source" => "sup-2", "target" => "gen-4"}
    ]
  }

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :data, @default_data)

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get, do: Agent.get(__MODULE__, fn state -> state end)

  def get_and_update(next_state) do
    Agent.get_and_update(__MODULE__, fn current_state ->
      {{current_state, next_state}, next_state}
    end)
  end
end
