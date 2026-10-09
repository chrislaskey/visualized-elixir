defmodule Solar.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SolarWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:solar, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Solar.PubSub},
      SolarWeb.SupervisorsLive.Agent.Data,
      SolarWeb.SupervisorsLive.Agent.Processes,
      {Task, fn -> process_initial_agent_data_and_update_agent_processes() end},
      SolarWeb.SupervisorsLive.Presence,
      {SolarWeb.SupervisorsLive.Supervisor,
       name: SolarWeb.SupervisorsLive.Processes.root_process_name(),
       strategy: :one_for_one,
       type: "supervisor"},
      SolarWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Solar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SolarWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Helpers

  def process_initial_agent_data_and_update_agent_processes do
    data = SolarWeb.SupervisorsLive.Agent.Data.get()
    :ok = SolarWeb.SupervisorsLive.Processes.parse_and_store_child_processes(data)
    :ok
  end
end
