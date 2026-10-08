defmodule SolarWeb.SupervisorsLive.Index do
  use SolarWeb, :live_view

  @pubsub_topic "supervisors:updated"

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> when_connected_push_event_data()
      |> when_connected_subscribe_to_pubsub_topic()

    {:ok, socket}
  end

  @impl true
  def handle_event("data", params, socket) do
    {previous, next} = get_and_update_data(params)
    :ok = Phoenix.PubSub.broadcast(Solar.PubSub, @pubsub_topic, {:updated, next})

    reconcile_processes(previous, next)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated, data}, socket) do
    {:noreply, push_data_event(socket, data)}
  end

  # Helpers

  defp when_connected_push_event_data(socket) do
    if connected?(socket) do
      push_data_event(socket, get_data())
    else
      socket
    end
  end

  defp when_connected_subscribe_to_pubsub_topic(socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Solar.PubSub, @pubsub_topic)
      socket
    else
      socket
    end
  end

  def push_data_event(socket, data) do
    push_event(socket, "data", data)
  end

  def get_data do
    SolarWeb.SupervisorsLive.Agent.Data.get()
  end

  def get_and_update_data(data) do
    SolarWeb.SupervisorsLive.Agent.Data.get_and_update(data)
  end

  defp reconcile_processes(previous, next) do
    previous = cleanup_for_comparison(previous)
    next = cleanup_for_comparison(next)

    if previous != next || true do
      nodes = Map.get(next, "nodes", [])
      edges = Map.get(next, "edges", [])
      edges_lookup = Map.new(edges, fn edge -> {edge["target"], edge["source"]} end)

      processes_lookup =
        Enum.reduce(nodes, %{}, fn process_data, acc ->
          process_name = Map.get(process_data, "id")

          parent_name =
            Map.get(edges_lookup, process_name, "SolarWeb.SupervisorsLive.DynamicSupervisor")

          process_options =
            process_data
            |> Map.merge(process_data["data"])
            |> Map.delete("data")
            |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
            |> Map.put("")

          Map.update(acc, parent_name, %{process_name => process_options}, fn existing ->
            Map.put(existing, process_name, process_options)
          end)
        end)

      # TODO: Solve for restarts, where children that are dynamically added are lost.
      # One option would be to have the supervisor lookup the values in an
      # Agent on `init` instead of passing it in directly here?

      # TODO: add tree values to the agent first? Otherwise need to figure out
      # how to pass in nested child specs which is much more difficult?
      # TODO: store name as well?

      Enum.map(processes_lookup, fn {key, value} ->
        process =
          child_options = value

        SolarWeb.SupervisorsLive.Agent.Processes.set_children(key, value)
      end)

      # TODO: type

      #       "SolarWeb.SupervisorsLive.DynamicSupervisor" => %{
      #   "root" => %{
      #     "data" => %{
      #       "config" => %{"strategy" => "one_for_one"},
      #       "label" => "Supervisor 1",
      #       "root" => true
      #     },
      #     "id" => "root",
      #     "type" => "supervisor"
      #   }
      # },
      # "root" => %{
      #   "gen-3" => %{
      #     "data" => %{
      #       "config" => %{"restart" => "permanent"},
      #       "label" => "GenServer 3"
      #     },
      #     "id" => "gen-3",
      #     "type" => "worker"
      #   },
      #   "sup-2" => %{
      #     "data" => %{
      #       "config" => %{"strategy" => "one_for_all"},
      #       "label" => "Supervisor 2"
      #     },
      #     "id" => "sup-2",
      #     "type" => "supervisor"
      #   }
      # },

      # dbg processes_lookup
      #
      # parent_config = Map.get(processes_lookup,"SolarWeb.SupervisorsLive.DynamicSupervisor") 
      #
      # parent_options = []
      #
      # SolarWeb.SupervisorsLive.Supervisor.start_child(
      #   SolarWeb.SupervisorsLive.Supervisor,
      #   {SolarWeb.SupervisorsLive.Supervisor, opts}
      # )

      # parent_config = Map.get(processes_lookup,"SolarWeb.SupervisorsLive.DynamicSupervisor") 
      # parent_key = String.to_atom(parent_config["id"])
      # parent_pid = Process.whereis(parent_key)
      #
      # walk_nodes(processes_lookup, parent_config)
    end

    :ok
  end

  def cleanup_for_comparison(map) do
    map
    |> Map.delete("client_id")
    |> Map.update("nodes", [], fn current ->
      Enum.map(current, &Map.delete(&1, "position"))
    end)
  end

  # def walk_nodes(processes_lookup, parent_key) do
  #   parent_config = Map.get(processes_lookup, parent_key) 
  #   parent_key = String.to_atom(parent_config["id"])
  #   parent_pid = Process.whereis(parent_key)
  #
  #   process = Map.get(processes, key)
  #
  #   DynamicSupervisor.start_child()
  #
  #   # create children?
  #
  #   processes
  #   |> Map.get(key)
  #   |> Enum.map()
  # end
end
