defmodule SolarWeb.PageController do
  use SolarWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
