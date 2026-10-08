defmodule SolarWeb.SupervisorsLive.Presence do
  use Phoenix.Presence,
    otp_app: :solar,
    pubsub_server: Solar.PubSub

  defmodule Metadata do
    defstruct [:status]
  end

  def topic, do: "supervisors"

  def list, do: SolarWeb.SupervisorsLive.Presence.list(topic())

  # Process functions

  def track_pid(pid, name, metadata, options \\ []) do
    Task.start_link(fn ->
      if Keyword.get(options, :after), do: :timer.sleep(Keyword.get(options, :after))

      SolarWeb.SupervisorsLive.Presence.track(
        pid,
        SolarWeb.SupervisorsLive.Presence.topic(),
        name,
        struct(SolarWeb.SupervisorsLive.Presence.Metadata, metadata)
      )
    end)
  end

  def update_pid(pid, name, metadata, options \\ []) do
    Task.start_link(fn ->
      if Keyword.get(options, :after), do: :timer.sleep(Keyword.get(options, :after))

      SolarWeb.SupervisorsLive.Presence.update(
        pid,
        SolarWeb.SupervisorsLive.Presence.topic(),
        name,
        fn current -> Map.merge(current, metadata) end
      )
    end)
  end
end
