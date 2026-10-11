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
        "id" => "sup-3",
        "type" => "supervisor",
        "position" => %{"x" => 360, "y" => 240},
        "data" => %{
          "label" => "Supervisor 3",
          "config" => %{
            "restart" => "permanent",
            "strategy" => "one_for_all"
          }
        }
      },
      %{
        "id" => "sup-4",
        "type" => "supervisor",
        "position" => %{"x" => 0, "y" => 500},
        "data" => %{
          "label" => "Supervisor 4",
          "config" => %{
            "restart" => "permanent",
            "strategy" => "one_for_all"
          }
        }
      }
    ],
    "edges" => [
      %{"id" => "root-sup-2", "source" => "root", "target" => "sup-2"},
      %{"id" => "root-sup-3", "source" => "root", "target" => "sup-3"},
      %{"id" => "sup-2-sup-4", "source" => "sup-2", "target" => "sup-4"}
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

  def default_data, do: @default_data
end
