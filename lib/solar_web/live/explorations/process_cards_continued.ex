defmodule SolarWeb.ExplorationsLive.ProcessCardsContinued do
  @moduledoc """
  Round two of the process card exploration, picking up four threads from
  round one: a status dot layered on the avatar's corner (the way the
  form_flow demo's user avatar carries its badge) instead of a ring, icons
  in the avatar instead of letters for the four kinds of process we will
  end up with (Supervisor, GenServer, GenStage producer, GenStage consumer),
  the sketch's silhouette restacked so the avatar sits in a header and the
  body and footer run full width, and the footer's four controls (Action,
  Config, Add, Logs) as icon buttons, with mockups of what each one opens.

  Everything is hardcoded and nothing is wired up.

  Mounted on `live "/explorations/process-cards-continued",
  ExplorationsLive.ProcessCardsContinued`.
  """

  use SolarWeb, :live_view

  alias SolarWeb.ExplorationsLive.Shared

  # -- Data ------------------------------------------------------------------

  @nodes %{
    supervisor: %{
      kind: :supervisor,
      label: "Supervisor 2",
      short: "su",
      order: "#2/3",
      kind_name: "Supervisor",
      subtitle: "one_for_all · gives up after 3 in 5s",
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
      short: "gs",
      order: "#3/3",
      kind_name: "GenServer",
      subtitle: "permanent · always restarted",
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
      short: "pr",
      order: "#1/2",
      kind_name: "GenStage producer",
      subtitle: "DemandDispatcher · buffer 10 000",
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
      short: "co",
      order: "#2/2",
      kind_name: "GenStage consumer",
      subtitle: "max_demand 10 · min_demand 5",
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

  # Every class string is spelled out so Tailwind finds it in the source.
  @kind_styles %{
    supervisor: %{
      solid: "bg-violet-600 text-white",
      soft: "bg-violet-100 text-violet-700 dark:bg-violet-950/70 dark:text-violet-300",
      text: "text-violet-600 dark:text-violet-300"
    },
    worker: %{
      solid: "bg-sky-600 text-white",
      soft: "bg-sky-100 text-sky-700 dark:bg-sky-950/70 dark:text-sky-300",
      text: "text-sky-600 dark:text-sky-300"
    },
    producer: %{
      solid: "bg-amber-500 text-white",
      soft: "bg-amber-100 text-amber-700 dark:bg-amber-950/70 dark:text-amber-300",
      text: "text-amber-600 dark:text-amber-300"
    },
    consumer: %{
      solid: "bg-emerald-600 text-white",
      soft: "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/70 dark:text-emerald-300",
      text: "text-emerald-600 dark:text-emerald-300"
    }
  }

  @icon_sets [
    %{
      id: "structural",
      label: "Structural: stack, chip, out-tray, in-tray",
      icons: %{
        supervisor: "hero-square-3-stack-3d-mini",
        worker: "hero-cpu-chip-mini",
        producer: "hero-arrow-up-tray-mini",
        consumer: "hero-inbox-arrow-down-mini"
      }
    },
    %{
      id: "flow",
      label: "Flow: fork, cube, send, funnel",
      icons: %{
        supervisor: "hero-share-mini",
        worker: "hero-cube-mini",
        producer: "hero-paper-airplane-mini",
        consumer: "hero-funnel-mini"
      }
    },
    %{
      id: "role",
      label: "Role: shield, cog, megaphone, inbox",
      icons: %{
        supervisor: "hero-shield-check-mini",
        worker: "hero-cog-6-tooth-mini",
        producer: "hero-megaphone-mini",
        consumer: "hero-inbox-mini"
      }
    },
    %{
      id: "arrows",
      label: "Arrows: stack, chip, up, down",
      icons: %{
        supervisor: "hero-rectangle-stack-mini",
        worker: "hero-cpu-chip-mini",
        producer: "hero-arrow-up-circle-mini",
        consumer: "hero-arrow-down-circle-mini"
      }
    }
  ]

  @states [:running, :starting, :down, :none]

  @state_styles %{
    running: %{
      dot: "bg-emerald-500",
      glyph: "hero-check-micro",
      glyph_class: "text-white",
      text: "text-emerald-600 dark:text-emerald-400",
      label: "running"
    },
    starting: %{
      dot: "bg-amber-400 animate-pulse",
      glyph: "hero-arrow-path-micro",
      glyph_class: "text-white animate-spin",
      text: "text-amber-600 dark:text-amber-400",
      label: "starting"
    },
    down: %{
      dot: "bg-rose-500",
      glyph: "hero-x-mark-micro",
      glyph_class: "text-white",
      text: "text-rose-600 dark:text-rose-400",
      label: "down"
    },
    none: %{
      dot: "bg-base-100 border-2 border-dashed border-base-content/40",
      glyph: "hero-minus-micro",
      glyph_class: "text-base-content/50",
      text: "text-base-content/50",
      label: "not supervised"
    }
  }

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
    %{kind: :exited, detail: "** (RuntimeError) boom", at: "10:41:50.210"},
    %{kind: :started, detail: "#PID<0.377.0>", at: "10:40:12.004"}
  ]

  @sections [
    %{id: "h", title: "H · Status dot in the corner"},
    %{id: "i", title: "I · Icons in the avatar"},
    %{id: "j", title: "J · Stacked header, full-width body"},
    %{id: "k", title: "K · Four icon buttons in the footer"},
    %{id: "l", title: "L · What a click opens"},
    %{id: "m", title: "M · Put together"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Process cards, continued")
     |> assign(:sup, @nodes.supervisor)
     |> assign(:gen, @nodes.worker)
     |> assign(:producer, @nodes.producer)
     |> assign(:consumer, @nodes.consumer)
     |> assign(:nodes, @nodes)
     |> assign(:kinds, @kinds)
     |> assign(:icon_sets, @icon_sets)
     |> assign(:states, @states)
     |> assign(:events, @events)
     |> assign(:sections, @sections)}
  end

  defp kind_style(kind), do: Map.fetch!(@kind_styles, kind)
  defp state_style(state), do: Map.fetch!(@state_styles, state)
  defp icon_for(set_id, kind), do: Enum.find(@icon_sets, &(&1.id == set_id)).icons[kind]

  # The footer's buttons, minus Add on nodes nothing can be added to.
  defp buttons_for(node), do: Enum.reject(@buttons, &(&1.id == "add" and node.adds == []))

  # -- Page ------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-10">
        <header class="space-y-3">
          <Shared.back_link />
          <.h1>Process cards, continued</.h1>
          <p class="max-w-3xl text-base-content/70">
            Round two. A status dot layered on the avatar's corner instead of a ring, icons in the
            avatar for the four kinds of process the app will have, the sketch restacked with a header
            on top and a full-width body and footer, and the footer's four controls as icon buttons
            with mockups of what each one opens.
          </p>
          <nav class="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            <a :for={s <- @sections} href={"##{s.id}"} class="text-primary hover:underline">{s.title}</a>
            <.link navigate="/explorations/process-cards" class="text-base-content/50 hover:underline">
              ← Round one
            </.link>
          </nav>
        </header>

        <.section_h sup={@sup} gen={@gen} states={@states} />
        <.section_i nodes={@nodes} kinds={@kinds} icon_sets={@icon_sets} />
        <.section_j nodes={@nodes} kinds={@kinds} sup={@sup} gen={@gen} />
        <.section_k sup={@sup} gen={@gen} />
        <.section_l sup={@sup} gen={@gen} events={@events} />
        <.section_m nodes={@nodes} kinds={@kinds} />
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
      class="absolute -bottom-1.5 left-1/2 size-3 -translate-x-1/2 rounded-full border-2 border-base-100 bg-violet-500"
    />
    """
  end

  attr :tone, :string, default: "neutral"
  attr :class, :any, default: nil
  attr :title, :string, default: nil
  slot :inner_block, required: true

  defp btn(assigns) do
    styles = %{
      "neutral" => "border-base-300 hover:border-base-content/40 hover:bg-base-200",
      "add" =>
        "border-violet-300 text-violet-700 hover:bg-violet-50 dark:border-violet-700 dark:text-violet-300 dark:hover:bg-violet-950",
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
        "whitespace-nowrap rounded-md border px-1.5 py-0.5 text-[11px] font-medium transition-colors active:scale-95",
        @style,
        @class
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
    <div class="inline-flex rounded-md border border-base-300 bg-base-200/60 p-0.5">
      <button
        :for={o <- @options}
        type="button"
        class={[
          "rounded px-1.5 py-0.5 font-mono text-[10px] transition-colors",
          o == @value && "bg-base-100 font-semibold text-base-content shadow-sm",
          o != @value && "text-base-content/50 hover:text-base-content"
        ]}
      >
        {o}
      </button>
    </div>
    """
  end

  @doc false
  # The avatar: letters or an icon on a disc, with the status layered on a
  # corner the way the form_flow demo's user avatar carries its badge.
  #
  #   tone   "dark" | "kind" | "soft"      disc colour
  #   badge  "dot" | "glyph" | "count" | "ring" | "none"
  #   corner "br" | "tr"
  attr :node, :map, required: true
  attr :state, :atom, default: :running
  attr :icon, :string, default: nil
  attr :tone, :string, default: "dark"
  attr :badge, :string, default: "dot"
  attr :corner, :string, default: "br"
  attr :size, :string, default: "size-10"

  defp avatar(assigns) do
    tones = %{
      "dark" => "bg-base-content text-base-100",
      "kind" => kind_style(assigns.node.kind).solid,
      "soft" => kind_style(assigns.node.kind).soft
    }

    corners = %{"br" => "-bottom-0.5 -right-0.5", "tr" => "-top-0.5 -right-0.5"}

    assigns =
      assigns
      |> assign(:tone_class, Map.fetch!(tones, assigns.tone))
      |> assign(:corner_class, Map.fetch!(corners, assigns.corner))
      |> assign(:style, state_style(assigns.state))

    ~H"""
    <span class="relative inline-flex shrink-0">
      <span class={[
        "inline-flex items-center justify-center rounded-full font-medium",
        @size,
        @tone_class,
        @badge == "ring" && ["ring-2 ring-offset-2 ring-offset-base-100", ring_class(@state)]
      ]}>
        <.icon :if={@icon} name={@icon} class="size-5" />
        <span :if={!@icon} class="text-xs">{@node.short}</span>
      </span>
      <span
        :if={@badge == "dot"}
        class={["absolute size-3.5 rounded-full ring-2 ring-base-100", @corner_class, @style.dot]}
      />
      <span
        :if={@badge == "glyph"}
        class={[
          "absolute inline-flex size-4 items-center justify-center rounded-full ring-2 ring-base-100",
          @corner_class,
          @style.dot
        ]}
      >
        <.icon name={@style.glyph} class={["size-2.5", @style.glyph_class]} />
      </span>
      <span
        :if={@badge == "count"}
        class={[
          "absolute inline-flex size-4 items-center justify-center rounded-full font-mono text-[9px] font-semibold ring-2 ring-base-100",
          @corner_class,
          @style.dot,
          @style.glyph_class
        ]}
      >
        {if @state == :none, do: "–", else: @node.restarts}
      </span>
    </span>
    """
  end

  defp ring_class(:running), do: "ring-emerald-500"
  defp ring_class(:starting), do: "ring-amber-400 animate-pulse"
  defp ring_class(:down), do: "ring-rose-500"
  defp ring_class(:none), do: "ring-base-content/20"

  attr :node, :map, required: true
  attr :state, :atom, default: :running

  defp stats_row(assigns) do
    assigns = assign(assigns, :style, state_style(assigns.state))

    ~H"""
    <div class="flex gap-6 text-sm">
      <div>
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Status</div>
        <div class={["font-medium", @style.text]}>{@style.label}</div>
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

  attr :node, :map, required: true
  attr :state, :atom, default: :running

  defp stats_tiles(assigns) do
    assigns = assign(assigns, :style, state_style(assigns.state))

    ~H"""
    <div class="grid grid-cols-3 gap-2 text-sm">
      <div class="rounded-lg bg-base-200/50 px-2.5 py-1.5">
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Status</div>
        <div class={["font-medium", @style.text]}>{@style.label}</div>
      </div>
      <div class="rounded-lg bg-base-200/50 px-2.5 py-1.5">
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Restarts</div>
        <div class="font-mono">{@node.restarts}</div>
      </div>
      <div class="min-w-0 rounded-lg bg-base-200/50 px-2.5 py-1.5">
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Last exit</div>
        <div class="truncate font-mono" title={@node.last_exit}>{@node.last_exit || "–"}</div>
      </div>
    </div>
    """
  end

  attr :node, :map, required: true
  attr :state, :atom, default: :running

  defp stats_grid(assigns) do
    assigns = assign(assigns, :style, state_style(assigns.state))

    ~H"""
    <dl class="grid grid-cols-[auto_1fr_auto_1fr] items-baseline gap-x-3 gap-y-1 text-[11px]">
      <dt class="text-base-content/50">status</dt>
      <dd class={["font-medium", @style.text]}>{@style.label}</dd>
      <dt class="text-base-content/50">restarts</dt>
      <dd class="font-mono">{@node.restarts}</dd>
      <dt class="text-base-content/50">pid</dt>
      <dd class="font-mono">{@node.pid}</dd>
      <dt class="text-base-content/50">last exit</dt>
      <dd class="truncate font-mono" title={@node.last_exit}>{@node.last_exit || "–"}</dd>
    </dl>
    """
  end

  @doc false
  # The footer, six ways. All of them carry the same buttons from
  # buttons_for/1; `active` highlights one.
  attr :node, :map, required: true
  attr :variant, :string, default: "tabs"
  attr :active, :string, default: nil

  defp footer(assigns) do
    assigns = assign(assigns, :buttons, buttons_for(assigns.node))

    ~H"""
    <div class={[
      "bg-stone-200/40 inset-shadow-sm dark:bg-stone-800/40",
      @variant in ~w(tabs pills iconlabel icons) && "flex items-center gap-1 px-3 py-2 text-xs",
      @variant == "tabs" && "gap-6 py-2.5",
      @variant == "tabbar" && "grid grid-cols-4",
      @variant == "segmented" && "p-2"
    ]}>
      <%= case @variant do %>
        <% "tabs" -> %>
          <a
            :for={b <- @buttons}
            href="#"
            class={[
              "-my-1 border-b-2 py-1 transition-colors",
              b.id == @active && "border-base-content font-semibold text-base-content",
              b.id != @active && "border-transparent text-base-content/60 hover:text-base-content"
            ]}
          >
            {b.label}
          </a>
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
        <% "icons" -> %>
          <span class="mr-auto font-mono text-[10px] text-base-content/40">{@node.pid}</span>
          <button
            :for={b <- @buttons}
            type="button"
            title={b.label}
            aria-label={b.label}
            class={[
              "rounded-md p-1 transition-colors",
              b.id == @active && "bg-base-100 text-base-content shadow-sm",
              b.id != @active && "text-base-content/60 hover:bg-base-100/70 hover:text-base-content"
            ]}
          >
            <.icon name={b.icon} class="size-4" />
          </button>
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
        <% "segmented" -> %>
          <div class="flex divide-x divide-base-300 overflow-hidden rounded-md border border-base-300 bg-base-100 text-xs">
            <button
              :for={b <- @buttons}
              type="button"
              class={[
                "flex flex-1 items-center justify-center gap-1 py-1 transition-colors",
                b.id == @active && "bg-base-content font-semibold text-base-100",
                b.id != @active && "text-base-content/70 hover:bg-base-200"
              ]}
            >
              <.icon name={b.icon} class="size-3.5" /> {b.label}
            </button>
          </div>
      <% end %>
    </div>
    """
  end

  @doc false
  # What a footer button opens. Same content for the drawer, swap, popover
  # and sheet options; only the container differs.
  attr :node, :map, required: true
  attr :panel, :string, required: true
  attr :events, :list, default: []
  attr :compact, :boolean, default: false

  defp panel(assigns) do
    ~H"""
    <div :if={@panel == "action"} class="space-y-1.5">
      <div class="flex flex-wrap items-center gap-1">
        <.btn :for={a <- @node.actions} tone={a.tone} title={a.hint}>{a.label}</.btn>
        <span class="ml-auto font-mono text-[10px] text-base-content/40">{@node.pid}</span>
      </div>
      <p :if={!@compact} class="text-[10px] text-base-content/50">
        Hover a button for the call it makes. The supervisor's reaction shows up in Logs.
      </p>
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
        class="rounded-md border border-violet-300 px-2 py-1.5 text-left transition-colors hover:bg-violet-50 dark:border-violet-700 dark:hover:bg-violet-950"
      >
        <span class="text-[11px] font-medium text-violet-700 dark:text-violet-300">{a.label}</span>
        <span :if={!@compact} class="block text-[10px] leading-snug text-base-content/60">{a.hint}</span>
      </button>
    </div>
    <div :if={@panel == "logs"} class="space-y-1">
      <ol class="space-y-0.5 text-[11px]">
        <li
          :for={e <- Enum.take(@events, if(@compact, do: 3, else: 4))}
          class="flex items-center gap-2"
        >
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
  # The restacked sketch: a header (avatar left, title and subtitle right),
  # then the body and the stone footer at full width.
  #
  #   body    "stats" | "tiles" | "grid"
  #   footer  see footer/1
  #   open    nil | "drawer" | "swap" | "popover"   where the active panel goes
  attr :node, :map, required: true
  attr :state, :atom, default: :running
  attr :icon, :string, default: nil
  attr :tone, :string, default: "dark"
  attr :badge, :string, default: "dot"
  attr :body, :string, default: "stats"
  attr :footer, :string, default: "tabs"
  attr :active, :string, default: nil
  attr :open, :string, default: nil
  attr :events, :list, default: []
  attr :class, :any, default: "w-80"
  attr :selected, :boolean, default: false

  defp stacked_card(assigns) do
    ~H"""
    <div class={[
      "relative rounded-xl border bg-base-100 shadow-sm",
      @selected && "border-2 border-violet-400",
      !@selected && "border-base-300",
      @class
    ]}>
      <div class="flex items-center gap-3 px-4 pb-2 pt-3">
        <.avatar node={@node} state={@state} icon={@icon} tone={@tone} badge={@badge} />
        <div class="min-w-0 flex-1">
          <div class="flex items-baseline gap-2">
            <h3 class="truncate font-semibold">{@node.label}</h3>
            <span class="font-mono text-[10px] text-base-content/50">{@node.order}</span>
          </div>
          <p class="truncate text-xs text-base-content/60">
            <span class={kind_style(@node.kind).text}>{@node.kind_name}</span> · {@node.subtitle}
          </p>
        </div>
      </div>

      <div class="px-4 pb-3">
        <%= if @open == "swap" and @active do %>
          <.panel node={@node} panel={@active} events={@events} />
        <% else %>
          <.stats_row :if={@body == "stats"} node={@node} state={@state} />
          <.stats_tiles :if={@body == "tiles"} node={@node} state={@state} />
          <.stats_grid :if={@body == "grid"} node={@node} state={@state} />
        <% end %>
      </div>

      <div class={["overflow-hidden", ((@open == "drawer" and @active) && "") || "rounded-b-xl"]}>
        <.footer node={@node} variant={@footer} active={@active} />
      </div>

      <div :if={@open == "drawer" and @active} class="rounded-b-xl border-t border-base-300 px-4 py-3">
        <.panel node={@node} panel={@active} events={@events} />
      </div>

      <div
        :if={@open == "popover" and @active}
        class="absolute inset-x-3 bottom-11 z-10 rounded-lg border border-base-300 bg-base-100 px-3 py-2.5 shadow-xl"
      >
        <.panel node={@node} panel={@active} events={@events} compact />
        <span class="absolute -bottom-1.5 left-6 size-3 rotate-45 border-b border-r border-base-300 bg-base-100" />
      </div>

      <.handles bottom={@node.kind in [:supervisor, :producer]} />
    </div>
    """
  end

  # -- H · Status dot in the corner -----------------------------------------

  defp section_h(assigns) do
    ~H"""
    <Shared.section id="h" title="H · Status dot in the corner">
      <:intro>
        The status layered on the avatar's lower-right corner, the way the form_flow demo's user
        avatar carries its badge: a small disc with a ring of card background so it reads as sitting
        on top. Four states each; "not supervised" is a hollow dashed dot.
      </:intro>

      <Shared.option
        code="H1"
        title="Plain dot"
        note="Just colour. Smallest and quietest; the starting state pulses. The dot is the same size as the status dot used elsewhere so the two read as one thing."
      >
        <div :for={s <- @states} class="flex flex-col items-center gap-2">
          <.avatar node={@sup} state={s} badge="dot" />
          <Shared.caption>{state_style(s).label}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="H2"
        title="Dot with a glyph"
        note="A check, a spinning arrow, an x, or a dash inside a slightly larger disc. Readable without colour, which matters for the amber/green pair, at the cost of a busier corner."
      >
        <div :for={s <- @states} class="flex flex-col items-center gap-2">
          <.avatar node={@sup} state={s} badge="glyph" />
          <Shared.caption>{state_style(s).label}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="H3"
        title="Dot carries the restart count"
        note="The corner disc shows the number of restarts in the state's colour, so a node that has been bouncing says so from across the canvas. Frees the body from a restarts stat. Shows a dash when not supervised."
      >
        <div :for={s <- @states} class="flex flex-col items-center gap-2">
          <.avatar node={@sup} state={s} badge="count" />
          <Shared.caption>{state_style(s).label}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="H4"
        title="Placement and size"
        note="Bottom-right vs. top-right vs. round one's ring, on three disc sizes. Top-right competes with the title; bottom-right sits where the eye is already moving on toward the body."
      >
        <div class="flex flex-col gap-4">
          <div :for={size <- ["size-8", "size-10", "size-12"]} class="flex items-center gap-6">
            <.avatar node={@sup} state={:running} badge="dot" corner="br" size={size} />
            <.avatar node={@sup} state={:running} badge="dot" corner="tr" size={size} />
            <.avatar node={@sup} state={:running} badge="ring" size={size} />
            <.avatar node={@sup} state={:down} badge="glyph" corner="br" size={size} />
            <span class="font-mono text-[10px] text-base-content/40">{size}</span>
          </div>
          <Shared.caption>bottom-right · top-right · ring · glyph</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- I · Icons in the avatar ----------------------------------------------

  defp section_i(assigns) do
    ~H"""
    <Shared.section id="i" title="I · Icons in the avatar">
      <:intro>
        An icon instead of two letters, for the four kinds of process the app will have: Supervisor,
        GenServer, GenStage producer, GenStage consumer. Four candidate sets, then the same set on
        three disc tones, then icons against letters inside a real header.
      </:intro>

      <Shared.option
        code="I1"
        title="Four icon sets, four kinds"
        wide
        note="Each row is one set. Supervisor and GenServer need to look like a container and a unit; producer and consumer need to look like a pair. The structural set's trays make the best pair; the arrows set is the most literal."
      >
        <div class="flex flex-col gap-5">
          <div :for={set <- @icon_sets} class="flex items-center gap-6">
            <div :for={k <- @kinds} class="flex w-28 flex-col items-center gap-1.5">
              <.avatar node={@nodes[k]} icon={set.icons[k]} badge="none" />
              <span class="text-[10px] text-base-content/50">{@nodes[k].kind_name}</span>
            </div>
            <span class="text-xs text-base-content/60">{set.label}</span>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="I2"
        title="Disc tone"
        wide
        note="The structural set on a dark disc (kind only in the icon), on a solid disc coloured by kind (violet, sky, amber, emerald), and on a soft tint. Each with the corner status dot. The tint keeps the dot the loudest colour on the card."
      >
        <div class="flex flex-col gap-5">
          <div :for={tone <- ["dark", "kind", "soft"]} class="flex items-center gap-6">
            <div :for={k <- @kinds} class="flex w-28 flex-col items-center gap-1.5">
              <.avatar node={@nodes[k]} icon={icon_for("structural", k)} tone={tone} badge="dot" />
              <span class="text-[10px] text-base-content/50">{@nodes[k].kind_name}</span>
            </div>
            <span class="text-xs text-base-content/60">{tone}</span>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="I3"
        title="Icons vs. letters, in a header"
        wide
        note="The same stacked header with letters and with the structural icons, for all four kinds. Letters need the kind name in the subtitle to be understood; icons let the subtitle carry config instead."
      >
        <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
          <div :for={k <- @kinds} class="flex flex-col gap-2">
            <div class="flex items-center gap-3 rounded-xl border border-base-300 bg-base-100 px-4 py-3 shadow-sm">
              <.avatar node={@nodes[k]} badge="dot" />
              <div class="min-w-0">
                <div class="font-semibold">{@nodes[k].label}</div>
                <p class="truncate text-xs text-base-content/60">
                  {@nodes[k].kind_name} · {@nodes[k].subtitle}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-3 rounded-xl border border-base-300 bg-base-100 px-4 py-3 shadow-sm">
              <.avatar node={@nodes[k]} icon={icon_for("structural", k)} tone="soft" badge="dot" />
              <div class="min-w-0">
                <div class="font-semibold">{@nodes[k].label}</div>
                <p class="truncate text-xs text-base-content/60">{@nodes[k].subtitle}</p>
              </div>
            </div>
          </div>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- J · Stacked header, full-width body ----------------------------------

  defp section_j(assigns) do
    ~H"""
    <Shared.section id="j" title="J · Stacked header, full-width body">
      <:intro>
        A1 restacked: the avatar no longer owns the left column. A header runs across the top with
        the avatar on the left and the title and subtitle on the right; below it the body and the
        stone footer use the full width. Letters and corner dots here so only the layout changes.
      </:intro>

      <Shared.option
        code="J1"
        title="Stacked, text tabs"
        note="The direct translation of A1. The stat row gets the whole width so 'last exit' no longer truncates, and the footer's links sit flush with the card's edges."
      >
        <.stacked_card node={@sup} />
        <.stacked_card node={@gen} />
      </Shared.option>

      <Shared.option
        code="J2"
        title="Stacked, stat tiles"
        note="The three stats as tinted tiles. Heavier, but the tiles give the body a shape of its own instead of floating text between the header and the footer."
      >
        <.stacked_card node={@sup} body="tiles" />
        <.stacked_card node={@gen} body="tiles" />
      </Shared.option>

      <Shared.option
        code="J3"
        title="Stacked, key/value grid"
        note="Four facts in two columns: status, restarts, pid, last exit. Denser than the stat row and brings the pid back onto the card without a footer slot for it."
      >
        <.stacked_card node={@sup} body="grid" />
        <.stacked_card node={@gen} body="grid" />
      </Shared.option>

      <Shared.option
        code="J4"
        title="Stacked, all four kinds"
        wide
        note="J1 with the structural icons on soft discs, for a supervisor, a GenServer, a producer, and a consumer. Add is dropped from the footer where nothing can be added. The handles follow the kind: producers have an outgoing handle, consumers do not."
      >
        <.stacked_card
          :for={k <- @kinds}
          node={@nodes[k]}
          icon={icon_for("structural", k)}
          tone="soft"
          class="w-72"
        />
      </Shared.option>
    </Shared.section>
    """
  end

  # -- K · Four icon buttons in the footer ----------------------------------

  defp section_k(assigns) do
    ~H"""
    <Shared.section id="k" title="K · Four icon buttons in the footer">
      <:intro>
        B4's Action button applied to all four controls: Action (bolt), Config (sliders), Add (plus),
        and a new Logs (list) for this process's own events. Each option is drawn with nothing active
        and with Action active.
      </:intro>

      <Shared.option
        code="K1"
        title="Pills, icon + label"
        note="Every button the same shape: icon and word in a rounded pill. The active one lifts onto a white pill. Four words fit a 320px card at 12px."
      >
        <.stacked_card node={@sup} footer="pills" />
        <.stacked_card node={@sup} footer="pills" active="action" />
      </Shared.option>

      <Shared.option
        code="K2"
        title="Icon only, label on the active one"
        note="B4 generalised: four icons, and only the active one spells its word. The space saved holds the pid on the right. Needs tooltips to learn, then it is the quietest."
      >
        <.stacked_card node={@sup} footer="iconlabel" />
        <.stacked_card node={@sup} footer="iconlabel" active="action" />
      </Shared.option>

      <Shared.option
        code="K3"
        title="Tab bar, icon over label"
        note="Four equal columns like a phone's tab bar, each an icon with a tiny label under it. Biggest click targets and most self-explanatory; also the tallest footer."
      >
        <.stacked_card node={@sup} footer="tabbar" />
        <.stacked_card node={@sup} footer="tabbar" active="action" />
      </Shared.option>

      <Shared.option
        code="K4"
        title="Icons only, pid on the left"
        note="Four icons right-aligned, the pid at the left, nothing else. Shortest footer of all. Relies entirely on tooltips and the icons being guessable."
      >
        <.stacked_card node={@sup} footer="icons" />
        <.stacked_card node={@sup} footer="icons" active="action" />
      </Shared.option>

      <Shared.option
        code="K5"
        title="Joined segmented bar"
        note="The four as one segmented control stretched across the footer, dividers between them, the active segment filled. Reads as 'pick one view', which is what the body-swap option in L needs."
      >
        <.stacked_card node={@sup} footer="segmented" />
        <.stacked_card node={@sup} footer="segmented" active="action" />
      </Shared.option>

      <Shared.option
        code="K6"
        title="On a GenServer (no Add)"
        note="K1 and K2 on a node nothing can be added to: the Add button is left out rather than disabled, so the footer never shows a dead control."
      >
        <.stacked_card node={@gen} footer="pills" active="config" />
        <.stacked_card node={@gen} footer="iconlabel" active="logs" />
      </Shared.option>
    </Shared.section>
    """
  end

  # -- L · What a click opens -----------------------------------------------

  defp section_l(assigns) do
    ~H"""
    <Shared.section id="l" title="L · What a click opens">
      <:intro>
        Four containers for the same four panels. Action is the row of process buttons with their
        calls as tooltips. Config is a segmented control with a one-line explanation. Add is the
        child types with a hint each. Logs is this process's own start/exit events, newest first.
      </:intro>

      <Shared.option
        code="L1"
        title="Drawer below the footer"
        wide
        note="The footer stays where it is and the panel slides out beneath it, so the card grows downward and the stats stay visible. A second click on the same button closes it."
      >
        <div :for={p <- ~w(action config add logs)} class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="pills" active={p} open="drawer" events={@events} />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="L2"
        title="Body swap"
        wide
        note="The panel replaces the stat row, so the card keeps its height and the tree never reflows. The stats come back when the active button is clicked again. Pairs naturally with K5's segmented footer."
      >
        <div :for={p <- ~w(action config add logs)} class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="segmented" active={p} open="swap" events={@events} />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="L3"
        title="Popover over the body"
        wide
        note="A floating panel anchored to the footer, covering the body (and, for Config and Logs, the header too) while open, gone on the next click anywhere. Nothing about the card moves. Compact versions of the panels, since they are transient."
      >
        <div :for={p <- ~w(action config add logs)} class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="iconlabel" active={p} open="popover" events={@events} />
          <Shared.caption>{p}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="L4"
        title="Side sheet"
        wide
        note="The button selects the node and switches the panel beside the canvas to that tab. Best for Logs, which wants more rows than a card can hold; heavier than it needs to be for Action."
      >
        <div class="flex flex-wrap items-start gap-6">
          <.stacked_card node={@sup} footer="pills" active="logs" selected />
          <.icon name="hero-arrow-long-right" class="mt-10 size-6 text-base-content/30" />
          <div class="w-80 rounded-xl border border-base-300 bg-base-100 shadow-sm">
            <div class="flex items-center gap-3 border-b border-base-300 px-4 py-3">
              <.avatar node={@sup} badge="dot" size="size-8" />
              <div class="min-w-0 flex-1">
                <div class="text-sm font-semibold">{@sup.label}</div>
                <div class="text-[11px] text-base-content/60">{@sup.kind_name} · {@sup.pid}</div>
              </div>
              <.icon name="hero-x-mark-micro" class="size-4 text-base-content/50" />
            </div>
            <div class="flex gap-1 border-b border-base-300 px-3 py-2 text-xs">
              <span
                :for={b <- buttons_for(@sup)}
                class={[
                  "flex items-center gap-1 rounded-md px-2 py-1",
                  b.id == "logs" && "bg-base-200 font-semibold",
                  b.id != "logs" && "text-base-content/60"
                ]}
              >
                <.icon name={b.icon} class="size-3.5" /> {b.label}
              </span>
            </div>
            <div class="px-4 py-3">
              <ol class="space-y-1 text-[11px]">
                <li :for={e <- @events} class="flex items-center gap-2">
                  <span class={[
                    "size-1.5 shrink-0 rounded-full",
                    e.kind == :started && "bg-emerald-500",
                    e.kind == :exited && "bg-rose-500"
                  ]} />
                  <span class="text-base-content/70">{e.kind}</span>
                  <span class="truncate font-mono">{e.detail}</span>
                  <time class="ml-auto shrink-0 font-mono text-[10px] text-base-content/40">
                    {e.at}
                  </time>
                </li>
              </ol>
              <p class="mt-3 text-[10px] text-base-content/50">
                Showing this process only. Clear the filter to see the whole tree's events.
              </p>
            </div>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="L5"
        title="Each button gets the container that suits it"
        wide
        note="Action and Add are quick, so they pop over. Config is an edit you want to see against the stats, so it drawers. Logs is long, so it opens the side sheet and the button just marks which node it is showing. One footer, three behaviours."
      >
        <div class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="pills" active="action" open="popover" events={@events} />
          <Shared.caption>Action: popover</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="pills" active="config" open="drawer" events={@events} />
          <Shared.caption>Config: drawer</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="pills" active="add" open="popover" events={@events} />
          <Shared.caption>Add: popover</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <.stacked_card node={@sup} footer="pills" active="logs" selected events={@events} />
          <Shared.caption>Logs: side sheet (L4)</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- M · Put together -----------------------------------------------------

  defp section_m(assigns) do
    ~H"""
    <Shared.section id="m" title="M · Put together">
      <:intro>
        Two candidates assembled from the above, each shown for all four kinds.
      </:intro>

      <Shared.option
        code="M1"
        title="Soft icon disc + corner dot + stat row + pills + drawer"
        wide
        note="I2's soft tint and structural icons, H1's dot, J1's body, K1's pills, L1's drawer. The config drawer is open on the producer to show the shape with a panel out."
      >
        <.stacked_card
          :for={k <- @kinds}
          node={@nodes[k]}
          icon={icon_for("structural", k)}
          tone="soft"
          footer="pills"
          active={if k == :producer, do: "config"}
          open="drawer"
          class="w-72"
        />
      </Shared.option>

      <Shared.option
        code="M2"
        title="Dark icon disc + restart-count dot + key/value grid + icons-only footer"
        wide
        note="I2's dark disc, H3's count in the corner (so the body drops restarts and can show the pid), J3's grid, K4's icons-only footer. The densest of the stacked options; the GenServer is drawn down with a popover open on Action."
      >
        <.stacked_card
          :for={k <- @kinds}
          node={@nodes[k]}
          state={if k == :worker, do: :down, else: :running}
          icon={icon_for("structural", k)}
          tone="dark"
          badge="count"
          body="grid"
          footer="icons"
          active={if k == :worker, do: "action"}
          open="popover"
          class="w-72"
        />
      </Shared.option>
    </Shared.section>
    """
  end
end
