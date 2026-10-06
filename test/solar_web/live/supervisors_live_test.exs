defmodule SolarWeb.SupervisorsLive.IndexTest do
  use SolarWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "mount pushes the graph to the hook", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/supervisors")

    assert_push_event(view, "data", %{"nodes" => [_ | _], "edges" => [_ | _]})
  end
end
