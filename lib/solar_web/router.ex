defmodule SolarWeb.Router do
  use SolarWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SolarWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SolarWeb do
    pipe_through :browser

    live "/", HomeLive.Index, :index
    live "/supervisors", SupervisorsLive.Index, :index
    live_dashboard "/dashboard", metrics: SolarWeb.Telemetry
  end
end
