defmodule SolarWeb.ExplorationsLive.ProcessCardsRoundThree do
  @moduledoc """
  Round three of the process card exploration. Decisions carried in from
  round two: colour means status and nothing else (no kind colours on discs,
  icons, or labels), the stacked header with a dark icon disc and a corner
  status dot, and a footer of icon buttons with K3's tab bar as the lean.

  What is still open is what a footer button opens. Round two's L options
  were all close and none right, so this page works the two ideas that came
  out of it - the drawer kept on the grey footer background, and body swap
  with a fifth Info tab as the way back - plus a few more ways to make the
  way back obvious.

  Everything is hardcoded and nothing is wired up.

  Mounted on `live "/explorations/process-cards-round-three",
  ExplorationsLive.ProcessCardsRoundThree`.
  """

  use SolarWeb, :live_view

  alias SolarWeb.ExplorationsLive.Shared

  # -- Data ------------------------------------------------------------------

  @nodes %{
    supervisor: %{
      kind: :supervisor,
      label: "Supervisor 2",
      order: "#2/3",
      kind_name: "Supervisor",
      subtitle: "one_for_all · gives up after 3 in 5s",
      icon: "hero-square-3-stack-3d-mini",
      pid: "#PID<0.412.0>",
      restarts: 2,
      last_exit: ":killed",
      config: %{
        label: "strategy",
        value: "one_for_all",
        options: ~w(one_for_one one_for_all rest_for_one),
        note: "One crashes, every sibling restarts. Gives up after 3 restarts in 5s."
      },
      actions: [
        %{label: "Kill", tone: "danger", hint: "Process.exit(pid, :kill)"},
        %{label: "Stop", tone: "warn", hint: "Supervisor.stop(pid, :normal)"},
        %{label: "Delete", tone: "neutral", hint: "removes the subtree"}
      ],
      adds: [
        %{label: "+ Supervisor", hint: "A child supervisor with its own strategy"},
        %{label: "+ GenServer", hint: "A child GenServer you can crash"}
      ]
    },
    worker: %{
      kind: :worker,
      label: "GenServer 4",
      order: "#3/3",
      kind_name: "GenServer",
      subtitle: "permanent · always restarted",
      icon: "hero-cpu-chip-mini",
      pid: "#PID<0.418.0>",
      restarts: 1,
      last_exit: "** (RuntimeError) boom",
      config: %{
        label: "restart",
        value: "permanent",
        options: ~w(permanent transient temporary),
        note: "Always restarted, even after a normal stop."
      },
      actions: [
        %{label: "Crash", tone: "danger", hint: "raise inside handle_call"},
        %{label: "Kill", tone: "danger", hint: "Process.exit(pid, :kill)"},
        %{label: "Stop", tone: "warn", hint: "exit :normal"},
        %{label: "Delete", tone: "neutral", hint: "removes the node"}
      ],
      adds: []
    },
    producer: %{
      kind: :producer,
      label: "Producer 1",
      order: "#1/2",
      kind_name: "GenStage producer",
      subtitle: "DemandDispatcher · buffer 10 000",
      icon: "hero-arrow-up-tray-mini",
      pid: "#PID<0.431.0>",
      restarts: 0,
      last_exit: nil,
      config: %{
        label: "dispatcher",
        value: "Demand",
        options: ~w(Demand Broadcast Partition),
        note: "Events go to whichever consumer asked first. Buffers 10 000 when nobody asks."
      },
      actions: [
        %{label: "Emit 10", tone: "add", hint: "push 10 events"},
        %{label: "Crash", tone: "danger", hint: "raise inside handle_demand"},
        %{label: "Kill", tone: "danger", hint: "Process.exit(pid, :kill)"},
        %{label: "Delete", tone: "neutral", hint: "removes the stage"}
      ],
      adds: [
        %{label: "+ Consumer", hint: "Subscribes to this producer"},
        %{label: "+ ProducerConsumer", hint: "Transforms events, then re-emits them"}
      ]
    },
    consumer: %{
      kind: :consumer,
      label: "Consumer 1",
      order: "#2/2",
      kind_name: "GenStage consumer",
      subtitle: "max_demand 10 · min_demand 5",
      icon: "hero-inbox-arrow-down-mini",
      pid: "#PID<0.436.0>",
      restarts: 0,
      last_exit: nil,
      config: %{
        label: "max_demand",
        value: "10",
        options: ~w(1 10 100 1000),
        note: "Asks for up to 10 events at a time and asks again once 5 are left."
      },
      actions: [
        %{label: "Crash", tone: "danger", hint: "raise inside handle_events"},
        %{label: "Kill", tone: "danger", hint: "Process.exit(pid, :kill)"},
        %{label: "Stop", tone: "warn", hint: "exit :normal"},
        %{label: "Delete", tone: "neutral", hint: "removes the stage"}
      ],
      adds: []
    }
  }

  @kinds [:supervisor, :worker, :producer, :consumer]
  @states [:running, :starting, :down, :none]

  @state_styles %{
    running: %{
      dot: "bg-emerald-500",
      text: "text-emerald-600 dark:text-emerald-400",
      label: "running"
    },
    starting: %{
      dot: "bg-amber-400 animate-pulse",
      text: "text-amber-600 dark:text-amber-400",
      label: "starting"
    },
    down: %{dot: "bg-rose-500", text: "text-rose-600 dark:text-rose-400", label: "down"},
    none: %{
      dot: "bg-base-100 border-2 border-dashed border-base-content/40",
      text: "text-base-content/50",
      label: "not supervised"
    }
  }

  @info %{id: "info", label: "Info", icon: "hero-information-circle-micro"}

  @buttons [
    %{id: "action", label: "Action", icon: "hero-bolt-micro"},
    %{id: "config", label: "Config", icon: "hero-adjustments-horizontal-micro"},
    %{id: "add", label: "Add", icon: "hero-plus-micro"},
    %{id: "logs", label: "Logs", icon: "hero-list-bullet-micro"}
  ]

  @events [
    %{kind: :started, detail: "#PID<0.412.0>", at: "10:42:07.118"},
    %{kind: :exited, detail: ":killed", at: "10:42:07.102"},
    %{kind: :started, detail: "#PID<0.398.0>", at: "10:41:50.221"},
    %{kind: :exited, detail: "** (RuntimeError) boom", at: "10:41:50.210"}
  ]

  @panels ~w(action config add logs)

  @sections [
    %{id: "n", title: "N · Colour is status only"},
    %{id: "o", title: "O · The three footers, side by side"},
    %{id: "p", title: "P · What a click opens, round three"},
    %{id: "q", title: "Q · Candidates, all four kinds"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Process cards, round three")
     |> assign(:sup, @nodes.supervisor)
     |> assign(:gen, @nodes.worker)
     |> assign(:nodes, @nodes)
     |> assign(:kinds, @kinds)
     |> assign(:states, @states)
     |> assign(:panels, @panels)
     |> assign(:events, @events)
     |> assign(:sections, @sections)}
  end

  defp state_style(state), do: Map.fetch!(@state_styles, state)

  # The footer's buttons: Info first when asked for, Add dropped on nodes
  # nothing can be added to.
  defp buttons_for(node, info?) do
    buttons = Enum.reject(@buttons, &(&1.id == "add" and node.adds == []))
    if info?, do: [@info | buttons], else: buttons
  end

  # -- Page ------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-10">
        <header class="space-y-3">
          <Shared.back_link />
          <.h1>Process cards, round three</.h1>
          <p class="max-w-3xl text-base-content/70">
            Colour now means status and nothing else. The stacked header and the icon-button footer
            are settled enough to draw everything with; what is still open is what a footer button
            opens, so most of this page is that.
          </p>
          <nav class="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            <a :for={s <- @sections} href={"##{s.id}"} class="text-primary hover:underline">{s.title}</a>
            <.link
              navigate="/explorations/process-cards-continued"
              class="text-base-content/50 hover:underline"
            >
              ← Round two
            </.link>
          </nav>
        </header>

        <.section_n nodes={@nodes} kinds={@kinds} sup={@sup} gen={@gen} states={@states} />
        <.section_o sup={@sup} gen={@gen} />
        <.section_p sup={@sup} gen={@gen} panels={@panels} events={@events} />
        <.section_q nodes={@nodes} kinds={@kinds} events={@events} />
      </div>
    </Layouts.app>
    """
  end

  # -- Building blocks -------------------------------------------------------

  attr :top, :boolean, default: true
  attr :bottom, :boolean, default: true

  defp handles(assigns) do
    ~H"""
    <span
      :if={@top}
      class="absolute -top-1.5 left-1/2 size-3 -translate-x-1/2 rounded-full border-2 border-base-100 bg-base-content/40"
    />
    <span
      :if={@bottom}
      class="absolute -bottom-1.5 left-1/2 size-3 -translate-x-1/2 rounded-full border-2 border-base-100 bg-base-content/40"
    />
    """
  end

  attr :tone, :string, default: "neutral"
  attr :title, :string, default: nil
  slot :inner_block, required: true

  defp btn(assigns) do
    styles = %{
      "neutral" => "border-base-300 hover:border-base-content/40 hover:bg-base-200",
      "add" => "border-base-content/40 hover:bg-base-200",
      "danger" =>
        "border-rose-300 text-rose-700 hover:bg-rose-50 dark:border-rose-800 dark:text-rose-300 dark:hover:bg-rose-950",
      "warn" =>
        "border-amber-300 text-amber-700 hover:bg-amber-50 dark:border-amber-800 dark:text-amber-300 dark:hover:bg-amber-950"
    }

    assigns = assign(assigns, :style, Map.fetch!(styles, assigns.tone))

    ~H"""
    <button
      type="button"
      title={@title}
      class={[
        "whitespace-nowrap rounded-md border bg-base-100 px-1.5 py-0.5 text-[11px] font-medium transition-colors active:scale-95",
        @style
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :value, :string, required: true
  attr :options, :list, required: true

  defp segmented(assigns) do
    ~H"""
    <div class="inline-flex rounded-md border border-base-300 bg-base-100 p-0.5">
      <button
        :for={o <- @options}
        type="button"
        class={[
          "rounded px-1.5 py-0.5 font-mono text-[10px] transition-colors",
          o == @value && "bg-base-content font-semibold text-base-100",
          o != @value && "text-base-content/60 hover:text-base-content"
        ]}
      >
        {o}
      </button>
    </div>
    """
  end

  # The avatar: an icon on a neutral disc, status dot on the lower-right.
  #   disc "dark" | "grey" | "outline"
  attr :node, :map, required: true
  attr :state, :atom, default: :running
  attr :disc, :string, default: "dark"
  attr :size, :string, default: "size-10"

  defp avatar(assigns) do
    discs = %{
      "dark" => "bg-base-content text-base-100",
      "grey" => "bg-base-200 text-base-content",
      "outline" => "border border-base-300 bg-base-100 text-base-content"
    }

    assigns =
      assigns
      |> assign(:disc_class, Map.fetch!(discs, assigns.disc))
      |> assign(:style, state_style(assigns.state))

    ~H"""
    <span class="relative inline-flex shrink-0">
      <span class={["inline-flex items-center justify-center rounded-full", @size, @disc_class]}>
        <.icon name={@node.icon} class="size-5" />
      </span>
      <span class={[
        "absolute -bottom-0.5 -right-0.5 size-3.5 rounded-full ring-2 ring-base-100",
        @style.dot
      ]} />
    </span>
    """
  end

  attr :node, :map, required: true
  attr :state, :atom, default: :running

  defp stats_row(assigns) do
    assigns = assign(assigns, :style, state_style(assigns.state))

    ~H"""
    <div class="flex gap-6 text-sm">
      <div>
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Status</div>
        <div class={["whitespace-nowrap font-medium", @style.text]}>{@style.label}</div>
      </div>
      <div>
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Restarts</div>
        <div class="font-mono">{if @state == :none, do: "–", else: @node.restarts}</div>
      </div>
      <div class="min-w-0">
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Last exit</div>
        <div class="truncate font-mono" title={@node.last_exit}>{@node.last_exit || "–"}</div>
      </div>
    </div>
    """
  end

  # One line of status, for places the stat row has been swapped out.
  attr :node, :map, required: true
  attr :state, :atom, default: :running
  attr :class, :any, default: nil

  defp status_line(assigns) do
    assigns = assign(assigns, :style, state_style(assigns.state))

    ~H"""
    <p class={["flex items-center gap-1.5 truncate text-[11px] text-base-content/60", @class]}>
      <span class={["size-1.5 shrink-0 rounded-full", @style.dot]} />
      <span class={["font-medium", @style.text]}>{@style.label}</span>
      <span>· {@node.restarts} restarts</span>
      <span :if={@node.last_exit} class="truncate">· last
      <span class="font-mono">{@node.last_exit}</span></span>
    </p>
    """
  end

  # The footer. `info` adds the Info tab in first position.
  #   variant "tabbar" | "pills" | "iconlabel"
  attr :node, :map, required: true
  attr :variant, :string, default: "tabbar"
  attr :active, :string, default: nil
  attr :info, :boolean, default: false
  attr :class, :any, default: nil

  defp footer(assigns) do
    assigns = assign(assigns, :buttons, buttons_for(assigns.node, assigns.info))

    ~H"""
    <div class={[
      "bg-stone-200/40 dark:bg-stone-800/40",
      @variant == "tabbar" && "grid",
      @variant == "tabbar" && length(@buttons) == 5 && "grid-cols-5",
      @variant == "tabbar" && length(@buttons) == 4 && "grid-cols-4",
      @variant == "tabbar" && length(@buttons) == 3 && "grid-cols-3",
      @variant in ~w(pills iconlabel) && "flex items-center gap-1 px-3 py-2 text-xs",
      @class
    ]}>
      <%= case @variant do %>
        <% "tabbar" -> %>
          <button
            :for={b <- @buttons}
            type="button"
            class={[
              "flex flex-col items-center gap-0.5 py-1.5 text-[10px] transition-colors",
              b.id == @active && "font-semibold text-base-content",
              b.id != @active && "text-base-content/50 hover:text-base-content"
            ]}
          >
            <.icon name={b.icon} class="size-4" />
            {b.label}
          </button>
        <% "pills" -> %>
          <button
            :for={b <- @buttons}
            type="button"
            class={[
              "flex items-center gap-1 rounded-md px-2 py-1 transition-colors",
              b.id == @active && "bg-base-100 font-semibold text-base-content shadow-sm",
              b.id != @active && "text-base-content/60 hover:bg-base-100/70 hover:text-base-content"
            ]}
          >
            <.icon name={b.icon} class="size-3.5" /> {b.label}
          </button>
        <% "iconlabel" -> %>
          <button
            :for={b <- @buttons}
            type="button"
            title={b.label}
            class={[
              "flex items-center gap-1 rounded-md transition-colors",
              b.id == @active && "bg-base-100 px-2 py-1 font-semibold text-base-content shadow-sm",
              b.id != @active &&
                "p-1 text-base-content/60 hover:bg-base-100/70 hover:text-base-content"
            ]}
          >
            <.icon name={b.icon} class="size-3.5" />
            <span :if={b.id == @active}>{b.label}</span>
          </button>
          <span class="ml-auto font-mono text-[10px] text-base-content/40">{@node.pid}</span>
      <% end %>
    </div>
    """
  end

  # What a footer button opens. `heading` adds a small title row with a
  # close control, for the options where the way back needs to be explicit.
  attr :node, :map, required: true
  attr :panel, :string, required: true
  attr :events, :list, default: []
  attr :heading, :boolean, default: false

  defp panel(assigns) do
    ~H"""
    <div :if={@heading} class="mb-1.5 flex items-center justify-between">
      <span class="text-[10px] font-semibold uppercase tracking-wide text-base-content/50">
        {String.capitalize(@panel)}
      </span>
      <button
        type="button"
        title="Back to info"
        class="-mr-1 rounded p-0.5 text-base-content/50 hover:bg-base-100 hover:text-base-content"
      >
        <.icon name="hero-x-mark-micro" class="size-3.5" />
      </button>
    </div>
    <div :if={@panel == "action"} class="flex flex-wrap items-center gap-1">
      <.btn :for={a <- @node.actions} tone={a.tone} title={a.hint}>{a.label}</.btn>
      <span class="ml-auto font-mono text-[10px] text-base-content/40">{@node.pid}</span>
    </div>
    <div :if={@panel == "config"} class="space-y-1.5">
      <label class="flex flex-wrap items-center gap-2 text-[11px] text-base-content/60">
        {@node.config.label}
        <.segmented value={@node.config.value} options={@node.config.options} />
      </label>
      <p class="text-[10px] leading-snug text-base-content/50">{@node.config.note}</p>
    </div>
    <div :if={@panel == "add"} class="grid grid-cols-2 gap-1.5">
      <button
        :for={a <- @node.adds}
        type="button"
        class="rounded-md border border-base-300 bg-base-100 px-2 py-1.5 text-left transition-colors hover:border-base-content/40"
      >
        <span class="text-[11px] font-medium">{a.label}</span>
        <span class="block text-[10px] leading-snug text-base-content/60">{a.hint}</span>
      </button>
    </div>
    <div :if={@panel == "logs"} class="space-y-1">
      <ol class="space-y-0.5 text-[11px]">
        <li :for={e <- @events} class="flex items-center gap-2">
          <span class={[
            "size-1.5 shrink-0 rounded-full",
            e.kind == :started && "bg-emerald-500",
            e.kind == :exited && "bg-rose-500"
          ]} />
          <span class="text-base-content/70">{e.kind}</span>
          <span class="truncate font-mono text-base-content">{e.detail}</span>
          <time class="ml-auto shrink-0 font-mono text-[10px] text-base-content/40">{e.at}</time>
        </li>
      </ol>
      <div class="flex items-center justify-between text-[10px] text-base-content/50">
        <span>newest first · this process only</span>
        <a href="#" class="text-primary hover:underline">all events →</a>
      </div>
    </div>
    """
  end

  @doc false
  # The card. `open` says where the active panel goes:
  #
  #   nil            no panel, stats in the body
  #   "drawer"       grey drawer below the footer, continuous with it (P1)
  #   "drawer_above" grey drawer between the body and the footer (P2)
  #   "swap"         panel replaces the stat row (P3 with info, P4 with heading)
  #   "swap_line"    panel replaces the stat row; status moves to one line (P5, P6)
  #   "body_grey"    the whole body turns grey and holds the panel (P7)
  attr :node, :map, required: true
  attr :state, :atom, default: :running
  attr :disc, :string, default: "dark"
  attr :footer, :string, default: "tabbar"
  attr :info, :boolean, default: false
  attr :active, :string, default: nil
  attr :open, :string, default: nil
  attr :heading, :boolean, default: false
  attr :line, :string, default: "strip"
  attr :events, :list, default: []
  attr :class, :any, default: "w-80"

  defp card(assigns) do
    assigns = assign(assigns, :panel_open, assigns.active not in [nil, "info"])

    ~H"""
    <div class={["relative rounded-xl border border-base-300 bg-base-100 shadow-sm", @class]}>
      <div class="flex items-center gap-3 px-4 pb-2 pt-3">
        <.avatar node={@node} state={@state} disc={@disc} />
        <div class="min-w-0 flex-1">
          <div class="flex items-baseline gap-2">
            <h3 class="truncate font-semibold">{@node.label}</h3>
            <span class="font-mono text-[10px] text-base-content/50">{@node.order}</span>
          </div>
          <.status_line
            :if={@open == "swap_line" and @line == "subtitle" and @panel_open}
            node={@node}
            state={@state}
          />
          <p
            :if={!(@open == "swap_line" and @line == "subtitle" and @panel_open)}
            class="truncate text-xs text-base-content/60"
          >
            {@node.kind_name} · {@node.subtitle}
          </p>
        </div>
      </div>

      <%= cond do %>
        <% @open in ~w(swap swap_line) and @panel_open -> %>
          <div class="px-4 pb-3">
            <.status_line
              :if={@open == "swap_line" and @line == "strip"}
              node={@node}
              state={@state}
              class="mb-2 border-b border-base-300 pb-1.5"
            />
            <.panel node={@node} panel={@active} events={@events} heading={@heading} />
          </div>
        <% @open == "body_grey" and @panel_open -> %>
          <div class="bg-stone-200/40 px-4 py-3 dark:bg-stone-800/40">
            <.panel node={@node} panel={@active} events={@events} heading={@heading} />
          </div>
        <% true -> %>
          <div class="px-4 pb-3"><.stats_row node={@node} state={@state} /></div>
      <% end %>

      <div
        :if={@open == "drawer_above" and @panel_open}
        class="border-b border-base-content/10 bg-stone-200/40 px-4 py-3 dark:bg-stone-800/40"
      >
        <.panel node={@node} panel={@active} events={@events} heading={@heading} />
      </div>

      <.footer
        node={@node}
        variant={@footer}
        active={@active}
        info={@info}
        class={[
          "overflow-hidden",
          (@open == "body_grey" and @panel_open) && "border-t border-base-content/10",
          !(@open == "drawer" and @panel_open) && "rounded-b-xl"
        ]}
      />

      <div
        :if={@open == "drawer" and @panel_open}
        class="rounded-b-xl border-t border-base-content/10 bg-stone-200/40 px-4 py-3 dark:bg-stone-800/40"
      >
        <.panel node={@node} panel={@active} events={@events} heading={@heading} />
      </div>

      <.handles bottom={@node.kind in [:supervisor, :producer]} />
    </div>
    """
  end

  # -- N · Colour is status only --------------------------------------------

  defp section_n(assigns) do
    ~H"""
    <Shared.section id="n" title="N · Colour is status only">
      <:intro>
        The kind lives in the icon and the subtitle's first word, both neutral. The only colour on a
        card is the status dot and the status word. Three neutral discs, then the four states on one
        card to show that the dot is the only thing that changes.
      </:intro>

      <Shared.option
        code="N1"
        title="Disc: dark, grey, outline"
        wide
        note="The structural icons on a dark disc, a grey disc, and an outlined disc. Dark gives the header the most weight and the dot its best contrast; grey is the quietest; outline matches the card's own border."
      >
        <div class="flex flex-col gap-5">
          <div :for={disc <- ["dark", "grey", "outline"]} class="flex items-center gap-6">
            <div :for={k <- @kinds} class="flex w-28 flex-col items-center gap-1.5">
              <.avatar node={@nodes[k]} disc={disc} />
              <span class="text-[10px] text-base-content/50">{@nodes[k].kind_name}</span>
            </div>
            <span class="text-xs text-base-content/60">{disc}</span>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="N2"
        title="The four states on one card"
        wide
        note="Running, starting, down, not supervised. The dot and the status word carry it; nothing else moves."
      >
        <div :for={s <- @states} class="flex flex-col items-center">
          <.card node={@gen} state={s} class="w-72" />
          <Shared.caption>{state_style(s).label}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="N3"
        title="All four kinds, settled header"
        wide
        note="The dark disc and the neutral subtitle on all four kinds, with K3's tab bar. This is the baseline every option in P is drawn on."
      >
        <.card :for={k <- @kinds} node={@nodes[k]} class="w-72" />
      </Shared.option>
    </Shared.section>
    """
  end

  # -- O · The three footers ------------------------------------------------

  defp section_o(assigns) do
    ~H"""
    <Shared.section id="o" title="O · The three footers, side by side">
      <:intro>
        K3's tab bar (the lean), K1's pills, and K2's icon-with-label-on-active, each idle and with
        Config active, so the choice can be made on the same card.
      </:intro>

      <Shared.option
        code="O1"
        title="K3 · Tab bar"
        note="Biggest targets, every label visible. Tallest footer by about 10px."
      >
        <.card node={@sup} footer="tabbar" />
        <.card node={@sup} footer="tabbar" active="config" />
      </Shared.option>

      <Shared.option
        code="O2"
        title="K1 · Pills"
        note="Every label visible on one line. The active pill lifts to white."
      >
        <.card node={@sup} footer="pills" />
        <.card node={@sup} footer="pills" active="config" />
      </Shared.option>

      <Shared.option
        code="O3"
        title="K2 · Icon, label on active"
        note="Quietest; makes room for the pid. Only the active control says what it is."
      >
        <.card node={@sup} footer="iconlabel" />
        <.card node={@sup} footer="iconlabel" active="config" />
      </Shared.option>

      <Shared.option
        code="O4"
        title="K3 with a fifth Info tab"
        note="The tab bar with Info first, active by default, for the body-swap options below. Five columns still fit at 320px; on a GenServer it is four."
      >
        <.card node={@sup} footer="tabbar" info active="info" />
        <.card node={@gen} footer="tabbar" info active="info" />
      </Shared.option>
    </Shared.section>
    """
  end

  # -- P · What a click opens, round three ----------------------------------

  defp section_p(assigns) do
    ~H"""
    <Shared.section id="p" title="P · What a click opens, round three">
      <:intro>
        Round two's drawer and body swap, reworked. The drawer options keep the panel on the grey
        footer background so the footer and its panel read as one control. The swap options each
        give a different answer to "how do I get the stats back".
      </:intro>

      <Shared.option
        code="P1"
        title="Grey drawer below the tab bar"
        wide
        note="L1 with the drawer on the footer's grey. The tab bar and what it opened are one grey block at the bottom of the card; the white part above is always the facts. A hairline separates tabs from content."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card node={@sup} active={p} open="drawer" events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P2"
        title="Grey drawer above the tab bar"
        wide
        note="The same grey block, but the panel opens between the body and the tabs, so the tab bar stays the card's bottom edge and the handle never moves away from it. The panel reads as rising out of the footer."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card node={@sup} active={p} open="drawer_above" events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P3"
        title="Body swap with an Info tab"
        wide
        note="L2 plus a fifth tab. Info is the default view and is highlighted when the stats are showing, so the way back is the same gesture as the way in: pick a tab. Nothing is ever hidden without a visible tab for it."
      >
        <div :for={p <- ["info" | @panels]} class="flex flex-col items-center">
          <.card node={@sup} info active={p} open="swap" events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P4"
        title="Body swap with a panel heading and close"
        wide
        note="No Info tab. The swapped-in panel gets a small title row (ACTION, CONFIG) with an × on the right that returns to the stats. Clicking the active tab again does the same. Keeps four tabs; the cost is one more row in the body."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card node={@sup} active={p} open="swap" heading events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P5"
        title="Body swap, status collapses to a strip"
        wide
        note="When a panel is open the stat row shrinks to one line above it rather than disappearing, so status, restarts and last exit stay on the card. There is nothing to get back to, so no Info tab and no close: clicking the active tab again expands the strip."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card node={@sup} active={p} open="swap_line" line="strip" events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P6"
        title="Body swap, status moves into the subtitle"
        wide
        note="Like P5 but the one-line status takes the subtitle's place in the header while a panel is open, so the body is the panel alone. The config the subtitle normally shows is in the Config tab anyway."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card
            node={@sup}
            active={p}
            open="swap_line"
            line="subtitle"
            events={@events}
            class="w-72"
          />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P7"
        title="Body goes grey"
        wide
        note="Body swap where the open panel takes the footer's grey, so the card becomes a white header on a grey block: the grey is the mode you are in. Drawn with P4's heading and close as the way back."
      >
        <div :for={p <- @panels} class="flex flex-col items-center">
          <.card node={@sup} active={p} open="body_grey" heading events={@events} class="w-72" />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="P8"
        title="Grey drawer with the other footers"
        wide
        note="P1 on K1's pills and K2's icon-with-label, for the case where the tab bar is not the pick."
      >
        <div class="flex flex-col items-center">
          <.card
            node={@sup}
            footer="pills"
            active="config"
            open="drawer"
            events={@events}
            class="w-72"
          />
          <Shared.caption>pills</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.card
            node={@sup}
            footer="iconlabel"
            active="config"
            open="drawer"
            events={@events}
            class="w-72"
          />
          <Shared.caption>icon, label on active</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.card
            node={@gen}
            footer="pills"
            active="logs"
            open="drawer_above"
            events={@events}
            class="w-72"
          />
          <Shared.caption>pills, drawer above</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.card
            node={@gen}
            footer="iconlabel"
            active="action"
            open="drawer_above"
            events={@events}
            class="w-72"
          />
          <Shared.caption>icon, drawer above</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- Q · Candidates, all four kinds ---------------------------------------

  defp section_q(assigns) do
    ~H"""
    <Shared.section id="q" title="Q · Candidates, all four kinds">
      <:intro>
        The three P options that feel closest, each across the four kinds with a different panel open
        on each so the shapes can be compared in a row.
      </:intro>

      <Shared.option code="Q1" title="P1 · Grey drawer below the tab bar" wide>
        <.card
          :for={{k, p} <- Enum.zip(@kinds, [nil, "action", "config", "logs"])}
          node={@nodes[k]}
          active={p}
          open="drawer"
          events={@events}
          class="w-72"
        />
      </Shared.option>

      <Shared.option code="Q2" title="P3 · Body swap with an Info tab" wide>
        <.card
          :for={{k, p} <- Enum.zip(@kinds, ["info", "action", "config", "logs"])}
          node={@nodes[k]}
          info
          active={p}
          open="swap"
          events={@events}
          class="w-72"
        />
      </Shared.option>

      <Shared.option code="Q3" title="P5 · Body swap, status strip" wide>
        <.card
          :for={{k, p} <- Enum.zip(@kinds, [nil, "action", "config", "logs"])}
          node={@nodes[k]}
          active={p}
          open="swap_line"
          line="strip"
          events={@events}
          class="w-72"
        />
      </Shared.option>
    </Shared.section>
    """
  end
end
