defmodule SolarWeb.SupervisorsLive.Presence do
  use Phoenix.Presence,
    otp_app: :solar,
    pubsub_server: Solar.PubSub

  defmodule Metadata do
    defstruct [:pid, :status]
  end

  @topic "supervisors"

  @pubsub_topic "supervisors:status:updated"

  def topic, do: @topic

  def pubsub_topic, do: @pubsub_topic

  def list, do: SolarWeb.SupervisorsLive.Presence.list(topic())

  def status do
    list()
    |> Map.new(fn {key, value} -> {key, Map.get(value, :metas)} end)
    |> to_status()
  end

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

  # Client functions

  def init(_opts \\ []) do
    {:ok, %{}}
  end

  def handle_metas(_topic, _data, presences, state) do
    status = to_status(presences)

    :ok = Phoenix.PubSub.broadcast(Solar.PubSub, pubsub_topic(), {@pubsub_topic, status})

    {:ok, state}
  end

  # Helpers

  def to_status(presences) do
    Map.new(presences, fn {key, values} ->
      value =
        values
        |> hd()
        |> Map.drop([:__struct__, :phx_ref, :phx_ref_prev])

      {key, value}
    end)
  end
end
