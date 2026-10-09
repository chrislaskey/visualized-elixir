defmodule SolarWeb.SupervisorsLive.Index do
  use SolarWeb, :live_view

  @pubsub_topic_data "supervisors:data:updated"
  @pubsub_topic_status SolarWeb.SupervisorsLive.Presence.pubsub_topic()

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> when_connected_push_events()
      |> when_connected_subscribe_to_pubsub_topics()

    {:ok, socket}
  end

  @impl true
  def handle_event("data", params, socket) do
    {previous, next} = get_and_update_data(params)
    :ok = Phoenix.PubSub.broadcast(Solar.PubSub, @pubsub_topic_data, {@pubsub_topic_data, next})
    maybe_update_processes(previous, next)

    {:noreply, socket}
  end

  @impl true
  def handle_info({@pubsub_topic_data, data}, socket) do
    {:noreply, push_data_event(socket, data)}
  end

  def handle_info({@pubsub_topic_status, status}, socket) do
    {:noreply, push_status_event(socket, status)}
  end

  # Helpers

  defp when_connected_push_events(socket) do
    if connected?(socket) do
      socket
      |> push_data_event(get_data())
      |> push_status_event(get_status())
    else
      socket
    end
  end

  defp when_connected_subscribe_to_pubsub_topics(socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Solar.PubSub, @pubsub_topic_data)
      :ok = Phoenix.PubSub.subscribe(Solar.PubSub, @pubsub_topic_status)
      socket
    else
      socket
    end
  end

  def push_data_event(socket, data) do
    push_event(socket, "data", data)
  end

  def push_status_event(socket, status) do
    push_event(socket, "status", status)
  end

  def get_data do
    SolarWeb.SupervisorsLive.Agent.Data.get()
  end

  def get_status do
    SolarWeb.SupervisorsLive.Presence.status()
  end

  def get_and_update_data(data) do
    SolarWeb.SupervisorsLive.Agent.Data.get_and_update(data)
  end

  # Helpers - Processes

  defp maybe_update_processes(previous, next) do
    if processes_changed?(previous, next) do
      SolarWeb.SupervisorsLive.Processes.update(next)
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
end
