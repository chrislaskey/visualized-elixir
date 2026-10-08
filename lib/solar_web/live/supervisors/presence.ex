defmodule SolarWeb.SupervisorsLive.Presence do
  use Phoenix.Presence,
    otp_app: :solar,
    pubsub_server: Solar.PubSub

  defmodule Metadata do
    defstruct [:status]
  end

  @topic "supervisors"

  @pubsub_topic "supervisors:status:updated"

  def topic, do: @topic

  def pubsub_topic, do: @pubsub_topic

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

  # Client functions

  def init(_opts \\ []) do
    {:ok, %{}}
  end

  def handle_metas(_topic, _data, presences, state) do
    status =
      Map.new(presences, fn {key, values} ->
        values = Enum.map(values, &Map.drop(&1, [:__struct__, :phx_ref, :phx_ref_prev]))

        {key, values}
      end)

    :ok = Phoenix.PubSub.broadcast(Solar.PubSub, pubsub_topic(), {@pubsub_topic, status})

    {:ok, state}
  end
end
