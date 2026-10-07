defmodule SolarWeb.ExplorationsLive.Index do
  @moduledoc """
  Index of the design explorations: scratch pages where one piece of UI is
  drawn several ways side by side, so a direction can be picked by looking
  at it rather than by describing it.

  Each exploration is one page under `/explorations`, listed in
  `@explorations` here. Nothing on any of them is wired up - the data is
  hardcoded and the components are scratch copies, so picking a direction is
  a separate job from building it.

  Mounted on `live "/explorations", ExplorationsLive.Index`.
  """

  use SolarWeb, :live_view

  @explorations [
    %{
      path: "/explorations/process-cards",
      title: "Process cards",
      note: """
      The supervisor and GenServer cards on the supervision canvas: the same
      facts and controls as the example demo, organized many different ways -
      footer tabs, accordions, menus, toolbars, inspectors, modals, and more.
      """
    },
    %{
      path: "/explorations/process-cards-continued",
      title: "Process cards, continued",
      note: """
      Round two: a status dot on the avatar's corner, icons for all four
      kinds of process, the sketch restacked with a header on top, four icon
      buttons in the footer, and what each one opens.
      """
    },
    %{
      path: "/explorations/process-cards-round-three",
      title: "Process cards, round three",
      note: """
      Colour for status only, the three footers side by side, and eight
      more answers to what a footer button opens: grey drawers, and body
      swaps with an Info tab, a close, or a status strip as the way back.
      """
    }
  ]

  @doc "Every exploration, in the order the index lists them."
  def explorations, do: @explorations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Explorations")
     |> assign(:explorations, @explorations)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <header class="space-y-2">
          <.h1>Explorations</.h1>
          <p class="max-w-2xl text-base-content/70">
            Scratch pages iterating with LLMs on design where one piece of the
            interface is drawn several ways at once, so a direction can be
            picked by looking at it. Everything on them is hardcoded and
            nothing is wired up.
          </p>
        </header>

        <ul class="divide-y divide-base-300 border-y border-base-300">
          <li :for={e <- @explorations}>
            <.link
              navigate={e.path}
              class="group flex items-baseline justify-between gap-6 py-4 transition-colors hover:bg-base-200/60"
            >
              <div class="space-y-1">
                <h2 class="font-semibold group-hover:text-primary">{e.title}</h2>
                <p class="max-w-2xl text-sm text-base-content/60">{e.note}</p>
              </div>
              <span class="font-mono text-xs text-base-content/40">{e.path}</span>
            </.link>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
