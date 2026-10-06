defmodule SolarWeb.SupervisorsLive.Index do
  use SolarWeb, :live_view

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> push_data_when_connected()

    {:ok, socket}
  end

  # Helpers

  defp push_data_when_connected(socket) do
    if connected?(socket) do
      push_event(socket, "data", get_data())
    else
      socket
    end
  end

  def get_data do
    SolarWeb.SupervisorsLive.Agent.Data.get()
  end
end
