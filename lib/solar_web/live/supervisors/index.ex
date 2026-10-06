defmodule SolarWeb.SupervisorsLive.Index do
  use SolarWeb, :live_view

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> push_data_event_when_connected()

    {:ok, socket}
  end

  def handle_event("data", params, socket) do
    _data = update_data(params)

    {:noreply, socket}
  end

  # Helpers

  defp push_data_event_when_connected(socket) do
    if connected?(socket) do
      push_data_event(socket, get_data())
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
