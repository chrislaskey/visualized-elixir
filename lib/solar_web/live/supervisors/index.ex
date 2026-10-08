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
    maybe_reconcile_processes(previous, next)

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

  # Helpers - Processes

  defp maybe_reconcile_processes(previous, next) do
    if processes_changed?(previous, next) do
      previous
      |> parse_child_processes_by_parent(next)
      |> store_child_processes_by_parent_in_agent()

      restart_all_processes()
    end
  end

  defp processes_changed?(previous, next) do
    previous = cleanup_for_comparison(previous)
    next = cleanup_for_comparison(next)

    previous != next
  end

  defp cleanup_for_comparison(map) do
    map
    |> Map.delete("client_id")
    |> Map.update("nodes", [], fn current ->
      Enum.map(current, &Map.delete(&1, "position"))
    end)
  end

  defp parse_child_processes_by_parent(_previous, next) do
    nodes = Map.get(next, "nodes", [])
    edges = Map.get(next, "edges", [])
    edges_lookup = Map.new(edges, fn edge -> {edge["target"], edge["source"]} end)

    Enum.reduce(nodes, %{}, fn process_data, acc ->
      process_name = Map.get(process_data, "id")
      parent_name = Map.get(edges_lookup, process_name, "SolarWeb.SupervisorsLive.Supervisor")
      process_options = parse_child_process_options(process_name, process_data)

      Map.update(acc, parent_name, %{process_name => process_options}, fn existing ->
        Map.put(existing, process_name, process_options)
      end)
    end)
  end

  defp parse_child_process_options(process_name, process_data) do
    flattened_map =
      process_data["data"]
      |> Map.merge(Map.get(process_data["data"], "config", %{}))
      |> Map.merge(process_data)
      |> Map.delete("data")
      |> Map.delete("config")

    as_keyword_list =
      flattened_map
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
      |> Enum.into([])

    with_new_keys = Keyword.put(as_keyword_list, :name, String.to_atom(process_name))

    with_atom_values =
      Keyword.replace_lazy(with_new_keys, :strategy, fn value -> String.to_atom(value) end)

    with_atom_values
  end

  defp store_child_processes_by_parent_in_agent(processes_by_parent) do
    process_type_to_module_lookup = %{
      "supervisor" => SolarWeb.SupervisorsLive.Supervisor,
      "genserver" => SolarWeb.SupervisorsLive.Supervisor,
      "producer" => SolarWeb.SupervisorsLive.Supervisor,
      "consumer" => SolarWeb.SupervisorsLive.Supervisor
    }

    Enum.map(processes_by_parent, fn {key, value} ->
      name = String.to_atom(key)

      children =
        Enum.map(value, fn {_, child} ->
          child_module = Map.get(process_type_to_module_lookup, child[:type])
          child_options = child

          {child_module, child_options}
        end)

      SolarWeb.SupervisorsLive.Agent.Processes.set_children(name, children)
    end)

    :ok
  end

  defp restart_all_processes() do
    Supervisor.terminate_child(Solar.Supervisor, :"SolarWeb.SupervisorsLive.Supervisor")
    Supervisor.restart_child(Solar.Supervisor, :"SolarWeb.SupervisorsLive.Supervisor")
  end
end
