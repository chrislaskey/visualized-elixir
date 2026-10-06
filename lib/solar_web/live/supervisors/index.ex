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
    data = update_data(params)
    :ok = Phoenix.PubSub.broadcast(Solar.PubSub, @pubsub_topic, {:updated, data})

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

  def update_data(data) do
    SolarWeb.SupervisorsLive.Agent.Data.get_and_update(data)
  end
end
