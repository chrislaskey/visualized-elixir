defmodule SolarWeb.SupervisorsLive.Agent.Data do
  use Agent

  @default_data %{
    "nodes" => [
      %{"id" => "hello", "position" => %{"x" => 0, "y" => 0}, "data" => %{"label" => "Hello"}},
      %{"id" => "world", "position" => %{"x" => 0, "y" => 120}, "data" => %{"label" => "World"}}
    ],
    "edges" => [
      %{"id" => "hello-world", "source" => "hello", "target" => "world"}
    ]
  }

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :data, @default_data)

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def get, do: Agent.get(__MODULE__, fn state -> state end)

  def get_and_update(value) do
    Agent.get_and_update(__MODULE__, fn _state ->
      {value, value}
    end)
  end
end
