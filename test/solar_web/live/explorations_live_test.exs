defmodule SolarWeb.ExplorationsLiveTest do
  use SolarWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the index lists every exploration", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/explorations")

    for exploration <- SolarWeb.ExplorationsLive.Index.explorations() do
      assert html =~ exploration.title
      assert html =~ exploration.path
    end
  end

  test "process cards renders every section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/explorations/process-cards")

    for code <- ~w(A1 A2 B1 C1 C5 D1 E2 F3 G1) do
      assert html =~ ~s(<span class="font-mono text-xs text-primary">#{code}</span>)
    end

    assert html =~ "one_for_all"
    assert html =~ "GenServer 4"
  end

  test "process cards, continued renders every section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/explorations/process-cards-continued")

    for code <- ~w(H1 I1 J1 K1 L1 M1) do
      assert html =~ ~s(<span class="font-mono text-xs text-primary">#{code}</span>)
    end

    assert html =~ "GenStage producer"
    assert html =~ "Logs"
  end

  test "process cards, round three renders every section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/explorations/process-cards-round-three")

    for code <- ~w(N1 O1 P1 P3 Q1) do
      assert html =~ ~s(<span class="font-mono text-xs text-primary">#{code}</span>)
    end

    assert html =~ "Info"
  end
end
