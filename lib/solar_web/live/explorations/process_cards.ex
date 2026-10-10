defmodule SolarWeb.ExplorationsLive.ProcessCards do
  @moduledoc """
  Scratch page for the supervisor and GenServer cards on the supervision
  canvas. Every option carries the same facts and controls as the cards in
  the `example/` demo - identity, live status, config, and actions - but
  organizes them differently: footer tabs, accordions, menus, toolbars,
  inspectors, modals, and so on.

  Everything is hardcoded (one supervisor, one GenServer, a few status
  states) and nothing is wired up; selects and buttons do nothing. A few
  options use native `<details>` so a menu or accordion can be opened and
  closed to feel it out, but no state leaves the browser.

  Mounted on `live "/explorations/process-cards", ExplorationsLive.ProcessCards`.
  """

  use SolarWeb, :live_view

  alias SolarWeb.ExplorationsLive.Shared

  # -- Data ------------------------------------------------------------------

  @sup %{
    id: "sup_2",
    kind: :supervisor,
    label: "Supervisor 2",
    short: "su",
    root: false,
    index: 1,
    sibling_count: 3,
    attached: true,
    config: %{strategy: "one_for_all", max_restarts: 3, max_seconds: 5},
    status: %{state: :running, pid: "#PID<0.412.0>", starts: 3, last_exit: ":killed"}
  }

  @gen %{
    id: "gen_4",
    kind: :genserver,
    label: "GenServer 4",
    short: "gs",
    root: false,
    index: 2,
    sibling_count: 3,
    attached: true,
    config: %{restart: "permanent"},
    status: %{
      state: :running,
      pid: "#PID<0.418.0>",
      starts: 2,
      last_exit: "** (RuntimeError) boom"
    }
  }

  @strategies ~w(one_for_one one_for_all rest_for_one)
  @restarts ~w(permanent transient temporary)

  @strategy_help %{
    "one_for_one" => "Only the crashed child restarts.",
    "one_for_all" => "One crashes, every sibling restarts.",
    "rest_for_one" => "The crashed child and those started after it restart."
  }

  @restart_help %{
    "permanent" => "Always restarted, even after a normal stop.",
    "transient" => "Restarted only after an abnormal exit.",
    "temporary" => "Never restarted."
  }

  @status_styles %{
    running: %{
      dot: "bg-emerald-500",
      text: "text-emerald-600 dark:text-emerald-400",
      ring: "ring-emerald-500",
      tint: "bg-emerald-50 dark:bg-emerald-950/40",
      stripe: "border-l-emerald-500",
      label: "running"
    },
    starting: %{
      dot: "bg-amber-400 animate-pulse",
      text: "text-amber-600 dark:text-amber-400",
      ring: "ring-amber-400 animate-pulse",
      tint: "bg-amber-50 dark:bg-amber-950/40",
      stripe: "border-l-amber-400",
      label: "starting"
    },
    down: %{
      dot: "bg-rose-500",
      text: "text-rose-600 dark:text-rose-400",
      ring: "ring-rose-500",
      tint: "bg-rose-50 dark:bg-rose-950/40",
      stripe: "border-l-rose-500",
      label: "down"
    },
    none: %{
      dot: "bg-base-content/20",
      text: "text-base-content/50",
      ring: "ring-base-content/20",
      tint: "bg-base-200",
      stripe: "border-l-base-content/20",
      label: "not running"
    }
  }

  @sections [
    %{id: "a", title: "A · Starting points"},
    %{id: "b", title: "B · The sketch, developed"},
    %{id: "c", title: "C · Progressive disclosure"},
    %{id: "d", title: "D · Config as inline controls"},
    %{id: "e", title: "E · Status emphasis"},
    %{id: "f", title: "F · Shape and tone"},
    %{id: "g", title: "G · Combinations"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Process cards")
     |> assign(:sup, @sup)
     |> assign(:gen, @gen)
     |> assign(:root, %{
       @sup
       | root: true,
         label: "Application",
         short: "ap",
         index: 0,
         sibling_count: 1,
         config: %{@sup.config | strategy: "one_for_one"}
     })
     |> assign(:strategies, @strategies)
     |> assign(:restarts, @restarts)
     |> assign(:sections, @sections)}
  end

  defp status_style(nil), do: @status_styles.none
  defp status_style(%{state: state}), do: Map.get(@status_styles, state, @status_styles.none)

  defp restarts_of(%{status: %{starts: starts}}), do: max(starts - 1, 0)
  defp restarts_of(_), do: 0

  defp with_state(node, :none), do: %{node | attached: false, status: nil}
  defp with_state(node, state), do: %{node | status: %{node.status | state: state}}

  defp strategy_help(strategy), do: Map.fetch!(@strategy_help, strategy)
  defp restart_help(restart), do: Map.fetch!(@restart_help, restart)

  # -- Page ------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-10">
        <header class="space-y-3">
          <Shared.back_link />
          <.h1>Process cards</.h1>
          <p class="max-w-3xl text-base-content/70">
            The supervisor and GenServer cards on the supervision canvas, drawn many ways. Every option
            has to carry everything the example demo's cards carry; the question is where each thing
            lives and what is visible before you click.
          </p>
          <nav class="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            <a :for={s <- @sections} href={"##{s.id}"} class="text-primary hover:underline">{s.title}</a>
          </nav>
        </header>

        <.checklist />

        <.section_a sup={@sup} gen={@gen} root={@root} strategies={@strategies} restarts={@restarts} />
        <.section_b sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
        <.section_c sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
        <.section_d sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
        <.section_e sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
        <.section_f sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
        <.section_g sup={@sup} gen={@gen} strategies={@strategies} restarts={@restarts} />
      </div>
    </Layouts.app>
    """
  end

  # -- Checklist -------------------------------------------------------------

  defp checklist(assigns) do
    ~H"""
    <details class="group rounded-xl border border-base-300 bg-base-100">
      <summary class="flex cursor-pointer select-none items-center justify-between px-4 py-3 text-sm font-semibold">
        What every card has to carry
        <.icon
          name="hero-chevron-down-micro"
          class="size-4 transition-transform group-open:rotate-180"
        />
      </summary>
      <div class="grid grid-cols-1 gap-6 border-t border-base-300 px-4 py-4 text-sm md:grid-cols-2">
        <div class="space-y-2">
          <h3 class="font-semibold text-violet-600 dark:text-violet-300">Supervisor</h3>
          <ul class="list-disc space-y-1 pl-5 text-base-content/70">
            <li>Name, kind badge (root or Supervisor), start order under its parent (#2/3)</li>
            <li>
              Live status: running, starting, down, or not supervised; pid; restarts; last exit reason
            </li>
            <li>Strategy, editable: one_for_one, one_for_all, rest_for_one (fixed on the root)</li>
            <li>Max restarts and max seconds, read-only ("gives up after 3 restarts in 5s")</li>
            <li>
              Actions: add supervisor, add GenServer, kill, stop, delete (the root cannot be killed, stopped, or deleted)
            </li>
            <li>A target handle on top (unless root) and a source handle on the bottom</li>
          </ul>
        </div>
        <div class="space-y-2">
          <h3 class="font-semibold text-sky-600 dark:text-sky-300">GenServer</h3>
          <ul class="list-disc space-y-1 pl-5 text-base-content/70">
            <li>Name, kind badge (GenServer), start order under its parent</li>
            <li>Live status: the same four states, pid, restarts, last exit reason</li>
            <li>Restart, editable: permanent, transient, temporary</li>
            <li>Actions: crash, kill, stop, delete</li>
            <li>A target handle on top only</li>
          </ul>
        </div>
      </div>
    </details>
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

  attr :status, :map, default: nil
  attr :class, :any, default: "size-2"

  defp dot(assigns) do
    assigns = assign(assigns, :style, status_style(assigns.status))

    ~H"""
    <span class={["shrink-0 rounded-full", @class, @style.dot]} />
    """
  end

  attr :kind, :string, default: "neutral"
  attr :disabled, :boolean, default: false
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
        "border-amber-300 text-amber-700 hover:bg-amber-50 dark:border-amber-800 dark:text-amber-300 dark:hover:bg-amber-950",
      "solid" => "border-base-content bg-base-content text-base-100 hover:opacity-90"
    }

    assigns = assign(assigns, :style, Map.fetch!(styles, assigns.kind))

    ~H"""
    <button
      type="button"
      title={@title}
      disabled={@disabled}
      class={[
        "whitespace-nowrap rounded-md border px-1.5 py-0.5 text-[11px] font-medium transition-colors active:scale-95 disabled:cursor-not-allowed disabled:opacity-40",
        @style,
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :name, :string, required: true
  attr :title, :string, required: true
  attr :tone, :string, default: "neutral"
  attr :class, :any, default: nil

  defp icon_btn(assigns) do
    tones = %{
      "neutral" => "text-base-content/70 hover:bg-base-200 hover:text-base-content",
      "add" => "text-violet-600 hover:bg-violet-50 dark:text-violet-300 dark:hover:bg-violet-950",
      "danger" => "text-rose-600 hover:bg-rose-50 dark:text-rose-300 dark:hover:bg-rose-950",
      "warn" => "text-amber-600 hover:bg-amber-50 dark:text-amber-300 dark:hover:bg-amber-950"
    }

    assigns = assign(assigns, :tone_class, Map.fetch!(tones, assigns.tone))

    ~H"""
    <button
      type="button"
      title={@title}
      aria-label={@title}
      class={["rounded-md p-1 transition-colors active:scale-95", @tone_class, @class]}
    >
      <.icon name={@name} class="size-4" />
    </button>
    """
  end

  attr :value, :string, required: true
  attr :options, :list, required: true
  attr :class, :any, default: nil

  defp sel(assigns) do
    ~H"""
    <select class={[
      "rounded-md border border-base-300 bg-base-100 px-1.5 py-0.5 font-mono text-[11px] text-base-content outline-none transition-colors hover:border-base-content/40 focus:border-violet-500",
      @class
    ]}>
      <option :for={o <- @options} selected={o == @value}>{o}</option>
    </select>
    """
  end

  attr :value, :string, required: true
  attr :options, :list, required: true
  attr :class, :any, default: nil

  defp segmented(assigns) do
    ~H"""
    <div class={["inline-flex rounded-md border border-base-300 bg-base-200/60 p-0.5", @class]}>
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

  attr :node, :map, required: true

  defp kind_badge(assigns) do
    ~H"""
    <span class="rounded-full bg-base-100/70 px-1.5 py-px font-mono text-[10px] text-base-content/70">
      {cond do
        @node.root -> "root"
        @node.kind == :supervisor -> "Supervisor"
        true -> "GenServer"
      end}
    </span>
    """
  end

  attr :node, :map, required: true

  defp order(assigns) do
    ~H"""
    <span
      :if={!@node.root}
      class="font-mono text-[10px] text-base-content/50"
      title="Start order under the parent"
    >
      #{@node.index + 1}/{@node.sibling_count}
    </span>
    """
  end

  attr :node, :map, required: true
  attr :class, :any, default: "size-10 text-xs"

  defp avatar(assigns) do
    ~H"""
    <div class={[
      "flex shrink-0 items-center justify-center rounded-full font-medium",
      @node.kind == :supervisor && "bg-base-content text-base-100",
      @node.kind == :genserver && "bg-sky-600 text-white",
      @class
    ]}>
      {@node.short}
    </div>
    """
  end

  attr :node, :map, required: true

  defp status_line(assigns) do
    assigns =
      assigns
      |> assign(:style, status_style(assigns.node.status))
      |> assign(:restarts, restarts_of(assigns.node))

    ~H"""
    <div :if={!@node.attached} class="flex items-center gap-1.5 text-[11px] text-base-content/50">
      <span class="size-2 rounded-full border border-dashed border-base-content/40" /> not supervised, so not running
    </div>
    <div :if={@node.attached} class="space-y-0.5 text-[11px]">
      <div class="flex items-center gap-1.5">
        <.dot status={@node.status} />
        <span class={["font-medium", @style.text]}>{@style.label}</span>
        <span class="ml-auto font-mono text-[10px] text-base-content/50">{@node.status.pid}</span>
      </div>
      <div class="text-base-content/60">
        <div>restarts <span class="font-mono text-base-content">{@restarts}</span></div>
        <div :if={@node.status.last_exit} class="truncate" title={@node.status.last_exit}>
          last exit <span class="font-mono text-base-content">{@node.status.last_exit}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :node, :map, required: true
  attr :strategies, :list, required: true
  attr :restarts, :list, required: true
  attr :control, :string, default: "select"

  defp config_control(assigns) do
    ~H"""
    <%= if @node.kind == :supervisor do %>
      <div :if={@node.root} class="text-[11px] text-base-content/60">
        strategy <span class="font-mono text-base-content">{@node.config.strategy}</span>
        <span class="ml-1 text-base-content/40">(fixed; started by the application)</span>
      </div>
      <div :if={!@node.root} class="space-y-1">
        <label class="flex items-center gap-1.5 text-[11px] text-base-content/60">
          strategy
          <.sel
            :if={@control == "select"}
            value={@node.config.strategy}
            options={@strategies}
            class="flex-1"
          />
          <.segmented
            :if={@control == "segmented"}
            value={@node.config.strategy}
            options={@strategies}
          />
        </label>
        <div class="text-[10px] text-base-content/50">
          gives up after {@node.config.max_restarts} restarts in {@node.config.max_seconds}s
        </div>
      </div>
    <% else %>
      <label class="flex items-center gap-1.5 text-[11px] text-base-content/60">
        restart
        <.sel
          :if={@control == "select"}
          value={@node.config.restart}
          options={@restarts}
          class="flex-1"
        />
        <.segmented :if={@control == "segmented"} value={@node.config.restart} options={@restarts} />
      </label>
    <% end %>
    """
  end

  attr :node, :map, required: true
  attr :layout, :string, default: "rows"

  defp action_buttons(assigns) do
    ~H"""
    <%= if @node.kind == :supervisor do %>
      <div class="flex flex-wrap gap-1 pt-0.5">
        <.btn kind="add" title="Add a child supervisor">+ Supervisor</.btn>
        <.btn kind="add" title="Add a child GenServer">+ GenServer</.btn>
      </div>
      <div :if={!@node.root} class={["flex flex-wrap gap-1", @layout == "inline" && "pt-0.5"]}>
        <.btn kind="danger" disabled={!@node.attached} title="Process.exit(pid, :kill)">Kill</.btn>
        <.btn kind="warn" disabled={!@node.attached} title="Supervisor.stop(pid, :normal)">Stop</.btn>
        <.btn title="Remove this supervisor and everything under it">Delete</.btn>
      </div>
    <% else %>
      <div class="flex flex-wrap gap-1 pt-0.5">
        <.btn kind="danger" disabled={!@node.attached} title="raise inside the GenServer">Crash</.btn>
        <.btn kind="danger" disabled={!@node.attached} title="Process.exit(pid, :kill)">Kill</.btn>
        <.btn kind="warn" disabled={!@node.attached} title="exit with reason :normal">Stop</.btn>
        <.btn title="Remove this GenServer">Delete</.btn>
      </div>
    <% end %>
    """
  end

  attr :node, :map, required: true
  attr :size, :string, default: "size-4"

  defp action_icons(assigns) do
    ~H"""
    <%= if @node.kind == :supervisor do %>
      <.icon_btn name="hero-plus-micro" tone="add" title="Add a child supervisor" />
      <.icon_btn name="hero-plus-circle-micro" tone="add" title="Add a child GenServer" />
      <span :if={!@node.root} class="mx-0.5 h-4 w-px bg-base-300" />
      <.icon_btn :if={!@node.root} name="hero-x-mark-micro" tone="danger" title="Kill" />
      <.icon_btn :if={!@node.root} name="hero-stop-micro" tone="warn" title="Stop" />
      <.icon_btn :if={!@node.root} name="hero-trash-micro" title="Delete" />
    <% else %>
      <.icon_btn name="hero-bolt-micro" tone="danger" title="Crash" />
      <.icon_btn name="hero-x-mark-micro" tone="danger" title="Kill" />
      <.icon_btn name="hero-stop-micro" tone="warn" title="Stop" />
      <span class="mx-0.5 h-4 w-px bg-base-300" />
      <.icon_btn name="hero-trash-micro" title="Delete" />
    <% end %>
    """
  end

  # A menu listing every action, grouped. Used by the kebab, split button,
  # and context menu options.
  attr :node, :map, required: true
  attr :class, :any, default: nil
  attr :with_config, :boolean, default: false
  attr :strategies, :list, default: []
  attr :restarts, :list, default: []

  defp action_menu(assigns) do
    ~H"""
    <div class={[
      "w-48 overflow-hidden rounded-lg border border-base-300 bg-base-100 py-1 text-xs shadow-lg",
      @class
    ]}>
      <%= if @with_config do %>
        <div class="px-3 pb-1 pt-1.5 text-[10px] font-semibold uppercase tracking-wide text-base-content/40">
          Config
        </div>
        <div class="px-3 pb-2">
          <.config_control node={@node} strategies={@strategies} restarts={@restarts} />
        </div>
        <div class="my-1 border-t border-base-300" />
      <% end %>
      <%= if @node.kind == :supervisor do %>
        <div class="px-3 pb-1 pt-1.5 text-[10px] font-semibold uppercase tracking-wide text-base-content/40">
          Add child
        </div>
        <.menu_item icon="hero-plus-micro">Supervisor</.menu_item>
        <.menu_item icon="hero-plus-circle-micro">GenServer</.menu_item>
        <div :if={!@node.root} class="my-1 border-t border-base-300" />
        <div
          :if={!@node.root}
          class="px-3 pb-1 pt-1.5 text-[10px] font-semibold uppercase tracking-wide text-base-content/40"
        >
          Process
        </div>
        <.menu_item
          :if={!@node.root}
          icon="hero-x-mark-micro"
          tone="danger"
          hint="Process.exit(pid, :kill)"
        >
          Kill
        </.menu_item>
        <.menu_item
          :if={!@node.root}
          icon="hero-stop-micro"
          tone="warn"
          hint="Supervisor.stop(pid, :normal)"
        >
          Stop
        </.menu_item>
        <div :if={!@node.root} class="my-1 border-t border-base-300" />
        <.menu_item :if={!@node.root} icon="hero-trash-micro">Delete subtree</.menu_item>
      <% else %>
        <div class="px-3 pb-1 pt-1.5 text-[10px] font-semibold uppercase tracking-wide text-base-content/40">
          Process
        </div>
        <.menu_item icon="hero-bolt-micro" tone="danger" hint="raise inside handle_call">
          Crash
        </.menu_item>
        <.menu_item icon="hero-x-mark-micro" tone="danger" hint="Process.exit(pid, :kill)">
          Kill
        </.menu_item>
        <.menu_item icon="hero-stop-micro" tone="warn" hint="exit :normal">Stop</.menu_item>
        <div class="my-1 border-t border-base-300" />
        <.menu_item icon="hero-trash-micro">Delete</.menu_item>
      <% end %>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :tone, :string, default: "neutral"
  attr :hint, :string, default: nil
  slot :inner_block, required: true

  defp menu_item(assigns) do
    tones = %{
      "neutral" => "text-base-content",
      "danger" => "text-rose-600 dark:text-rose-300",
      "warn" => "text-amber-600 dark:text-amber-300"
    }

    assigns = assign(assigns, :tone_class, Map.fetch!(tones, assigns.tone))

    ~H"""
    <button
      type="button"
      class={[
        "flex w-full items-center gap-2 px-3 py-1.5 text-left transition-colors hover:bg-base-200",
        @tone_class
      ]}
    >
      <.icon name={@icon} class="size-3.5 shrink-0" />
      <span class="flex-1">{render_slot(@inner_block)}</span>
      <span :if={@hint} class="truncate font-mono text-[9px] text-base-content/40">{@hint}</span>
    </button>
    """
  end

  # The example demo's card, as the baseline. `accent` is the header tint.
  attr :node, :map, required: true
  attr :strategies, :list, required: true
  attr :restarts, :list, required: true
  attr :control, :string, default: "select"
  slot :inner_block

  defp example_card(assigns) do
    ~H"""
    <div class={[
      "relative rounded-xl border bg-base-100 shadow-md",
      (@control == "segmented" && "w-72") || "w-60",
      @node.attached && "border-base-300",
      !@node.attached && "border-dashed border-base-content/30 opacity-80"
    ]}>
      <div class={[
        "flex items-center gap-2 rounded-t-xl border-b border-base-300 px-3 py-1.5",
        @node.kind == :supervisor && "bg-violet-50 dark:bg-violet-950/40",
        @node.kind == :genserver && "bg-sky-50 dark:bg-sky-950/40"
      ]}>
        <span class="truncate text-xs font-semibold">{@node.label}</span>
        <span class="ml-auto" /><.kind_badge node={@node} />
        <.order node={@node} />
      </div>
      <div class="space-y-2 px-3 py-2">
        <.status_line node={@node} />
        <.config_control
          node={@node}
          strategies={@strategies}
          restarts={@restarts}
          control={@control}
        />
        <%= if @inner_block == [] do %>
          <.action_buttons node={@node} />
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </div>
      <.handles top={!@node.root} bottom={@node.kind == :supervisor} />
    </div>
    """
  end

  # -- A · Starting points ---------------------------------------------------

  defp section_a(assigns) do
    ~H"""
    <Shared.section id="a" title="A · Starting points">
      <:intro>
        The sketch from the top of the supervisors page, untouched, and the example demo's card as it
        stands today. Everything after this is measured against these two.
      </:intro>

      <Shared.option
        code="A1"
        title="The sketch (verbatim)"
        note="Copied as-is from the supervisors page: an avatar, a name, the strategy as a caption, a row of stats, and a footer bar of three links that stand in for Action / Config / Add."
      >
        <div class="flex border border-stone-200 rounded-xl shadow-sm w-80">
          <div class="flex-0 p-3 pr-4">
            <div class="rounded-full bg-stone-900 h-10 w-10 flex justify-center items-center">
              <span class="text-stone-100 text-xs">su</span>
            </div>
          </div>
          <div class="w-full">
            <div>
              <div class="flex mt-2">
                <h3 class="font-semibold">Supervisor</h3>
              </div>

              <div class="mb-1 text-xs mb-3 flex gap-2">
                <p>one-for-all</p>
              </div>

              <div class="text-sm mb-3 flex gap-2">
                <p>Status</p>
                <p>Restarts</p>
                <p>Other</p>
              </div>
            </div>

            <div class="flex bg-stone-200/30 w-full text-xs py-2.5 px-3 gap-6 rounded-tl rounded-br inset-shadow-sm">
              <a href="#">Action</a>
              <a href="#">Config</a>
              <a href="#">Add</a>
            </div>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="A2"
        title="The example demo's card"
        note="Where we are: header with name, kind, start order; status block; a select for config; every action as a text button. Honest and complete, but five buttons on a supervisor is a lot of chrome per node."
      >
        <div>
          <.example_card node={@sup} strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Supervisor</Shared.caption>
        </div>
        <div>
          <.example_card node={@gen} strategies={@strategies} restarts={@restarts} />
          <Shared.caption>GenServer</Shared.caption>
        </div>
        <div>
          <.example_card node={@root} strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Root</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- B · The sketch, developed ---------------------------------------------

  # A1 with real data and the footer links as tabs. `panel` is the open tab
  # (nil, "action", "config", "add"); `placement` says where the tab's
  # content goes.
  attr :node, :map, required: true
  attr :panel, :string, default: nil
  attr :placement, :string, default: "below"
  attr :strategies, :list, required: true
  attr :restarts, :list, required: true
  attr :avatar_ring, :boolean, default: false
  attr :menu, :boolean, default: false
  attr :control, :string, default: "text"
  attr :class, :any, default: "w-80"

  defp sketch_card(assigns) do
    assigns = assign(assigns, :style, status_style(assigns.node.status))

    ~H"""
    <div class={["relative flex rounded-xl border border-base-300 bg-base-100 shadow-sm", @class]}>
      <div class="p-3 pr-4">
        <.avatar
          node={@node}
          class={[
            "size-10 text-xs",
            @avatar_ring && ["ring-2 ring-offset-2 ring-offset-base-100", @style.ring]
          ]}
        />
      </div>
      <div class="min-w-0 w-full">
        <div class="pr-3">
          <div class="mt-2 flex items-baseline gap-2">
            <h3 class="truncate font-semibold">{@node.label}</h3>
            <.order node={@node} />
            <.icon_btn
              :if={@menu}
              name="hero-ellipsis-horizontal-micro"
              title="More"
              class="-mr-2 -mt-1 ml-auto"
            />
          </div>

          <div :if={@control == "segmented"} class="mb-3 mt-1">
            <.config_control
              node={@node}
              strategies={@strategies}
              restarts={@restarts}
              control="segmented"
            />
          </div>

          <div :if={@control == "text"} class="mb-3 mt-0.5 flex gap-2 text-xs">
            <p :if={@node.kind == :supervisor}>
              <span class="font-mono">{@node.config.strategy}</span>
              <span class="text-base-content/50">· gives up after {@node.config.max_restarts} in {@node.config.max_seconds}s</span>
            </p>
            <p :if={@node.kind == :genserver}>
              <span class="font-mono">{@node.config.restart}</span>
              <span class="text-base-content/50">· {restart_help(@node.config.restart)}</span>
            </p>
          </div>

          <%= if @placement == "replace" and @panel do %>
            <div class="mb-3">
              <.sketch_panel
                node={@node}
                panel={@panel}
                strategies={@strategies}
                restarts={@restarts}
              />
            </div>
          <% else %>
            <.sketch_stats node={@node} />
          <% end %>
        </div>

        <div class="flex gap-6 rounded-tl rounded-br bg-base-200/60 px-3 py-2.5 text-xs inset-shadow-sm">
          <.sketch_tab active={@panel == "action"}>Action</.sketch_tab>
          <.sketch_tab active={@panel == "config"}>Config</.sketch_tab>
          <.sketch_tab :if={@node.kind == :supervisor} active={@panel == "add"}>Add</.sketch_tab>
        </div>

        <div
          :if={@placement == "below" and @panel}
          class="rounded-br-xl border-t border-base-300 px-3 py-2.5"
        >
          <.sketch_panel node={@node} panel={@panel} strategies={@strategies} restarts={@restarts} />
        </div>
      </div>
      <.handles top={!@node.root} bottom={@node.kind == :supervisor} />
    </div>
    """
  end

  attr :active, :boolean, default: false
  slot :inner_block, required: true

  defp sketch_tab(assigns) do
    ~H"""
    <a
      href="#"
      class={[
        "-my-1 border-b-2 py-1 transition-colors",
        @active && "border-base-content font-semibold text-base-content",
        !@active && "border-transparent text-base-content/60 hover:text-base-content"
      ]}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :node, :map, required: true

  defp sketch_stats(assigns) do
    assigns =
      assigns
      |> assign(:style, status_style(assigns.node.status))
      |> assign(:restarts, restarts_of(assigns.node))

    ~H"""
    <div class="mb-3 flex gap-5 text-sm">
      <div>
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Status</div>
        <div class={["flex items-center gap-1.5 font-medium", @style.text]}>
          <.dot status={@node.status} />
          {if @node.attached, do: @style.label, else: "unsupervised"}
        </div>
      </div>
      <div>
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Restarts</div>
        <div class="font-mono">{@restarts}</div>
      </div>
      <div class="min-w-0">
        <div class="text-[10px] uppercase tracking-wide text-base-content/40">Last exit</div>
        <div class="truncate font-mono" title={@node.status && @node.status.last_exit}>
          {(@node.status && @node.status.last_exit) || "–"}
        </div>
      </div>
    </div>
    """
  end

  attr :node, :map, required: true
  attr :panel, :string, required: true
  attr :strategies, :list, required: true
  attr :restarts, :list, required: true

  defp sketch_panel(assigns) do
    ~H"""
    <div :if={@panel == "action"} class="flex flex-wrap items-center gap-1">
      <%= if @node.kind == :supervisor do %>
        <.btn kind="danger">Kill</.btn>
        <.btn kind="warn">Stop</.btn>
        <.btn>Delete</.btn>
      <% else %>
        <.btn kind="danger">Crash</.btn>
        <.btn kind="danger">Kill</.btn>
        <.btn kind="warn">Stop</.btn>
        <.btn>Delete</.btn>
      <% end %>
      <span class="ml-auto font-mono text-[10px] text-base-content/40">{@node.status &&
        @node.status.pid}</span>
    </div>
    <div :if={@panel == "config"}>
      <.config_control node={@node} strategies={@strategies} restarts={@restarts} />
    </div>
    <div :if={@panel == "add"} class="flex flex-wrap gap-1">
      <.btn kind="add">+ Supervisor</.btn>
      <.btn kind="add">+ GenServer</.btn>
    </div>
    """
  end

  defp section_b(assigns) do
    ~H"""
    <Shared.section id="b" title="B · The sketch, developed">
      <:intro>
        A1 with real data in it, and the footer links turned into tabs. The three states of each tab
        are drawn side by side rather than toggled.
      </:intro>

      <Shared.option
        code="B1"
        title="Footer tabs, drawer opens below"
        wide
        note="The footer stays a tab bar; the active tab's content slides out beneath it, so the card grows downward. Status, restarts, and last exit are always visible as a stat row; the strategy line carries the restart budget."
      >
        <div>
          <.sketch_card node={@sup} strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Closed</Shared.caption>
        </div>
        <div>
          <.sketch_card node={@sup} panel="action" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Action open</Shared.caption>
        </div>
        <div>
          <.sketch_card node={@sup} panel="config" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Config open</Shared.caption>
        </div>
        <div>
          <.sketch_card node={@sup} panel="add" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Add open</Shared.caption>
        </div>
        <div>
          <.sketch_card node={@gen} panel="action" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>GenServer, Action open (no Add tab)</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="B2"
        title="Footer tabs, content replaces the stat row"
        note="Like a mobile tab bar: the footer picks what the body shows, so the card never changes height. The cost is that status disappears while you are on Config or Add."
      >
        <div>
          <.sketch_card node={@sup} placement="replace" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Nothing selected: stats</Shared.caption>
        </div>
        <div>
          <.sketch_card
            node={@sup}
            panel="action"
            placement="replace"
            strategies={@strategies}
            restarts={@restarts}
          />
          <Shared.caption>Action</Shared.caption>
        </div>
        <div>
          <.sketch_card
            node={@sup}
            panel="config"
            placement="replace"
            strategies={@strategies}
            restarts={@restarts}
          />
          <Shared.caption>Config</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="B3"
        title="Same shape, no tabs"
        note="The sketch's layout but flattened: the footer holds the actual buttons, and config is an inline select on the strategy line. Nothing hidden, one click for everything."
      >
        <div class="relative flex w-80 rounded-xl border border-base-300 bg-base-100 shadow-sm">
          <div class="p-3 pr-4"><.avatar node={@sup} /></div>
          <div class="min-w-0 w-full">
            <div class="pr-3">
              <div class="mt-2 flex items-baseline gap-2">
                <h3 class="font-semibold">{@sup.label}</h3>
                <.order node={@sup} />
              </div>
              <div class="mb-3 mt-1">
                <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
              </div>
              <.sketch_stats node={@sup} />
            </div>
            <div class="flex items-center gap-1 rounded-tl rounded-br bg-base-200/60 px-3 py-2 text-xs inset-shadow-sm">
              <.btn kind="danger">Kill</.btn>
              <.btn kind="warn">Stop</.btn>
              <.btn>Delete</.btn>
              <span class="mx-1 h-4 w-px bg-base-300" />
              <.btn kind="add">+ Sup</.btn>
              <.btn kind="add">+ Gen</.btn>
            </div>
          </div>
          <.handles />
        </div>
      </Shared.option>

      <Shared.option
        code="B4"
        title="Footer tabs as icons"
        note="The three tabs become icons (bolt, sliders, plus) with the word only on the active one, which buys room for the pid in the footer."
      >
        <div class="relative flex w-80 rounded-xl border border-base-300 bg-base-100 shadow-sm">
          <div class="p-3 pr-4"><.avatar node={@sup} /></div>
          <div class="min-w-0 w-full">
            <div class="pr-3">
              <div class="mt-2 flex items-baseline gap-2">
                <h3 class="font-semibold">{@sup.label}</h3>
                <.order node={@sup} />
              </div>
              <div class="mb-3 mt-0.5 text-xs">
                <span class="font-mono">{@sup.config.strategy}</span>
                <span class="text-base-content/50">· 3 in 5s</span>
              </div>
              <.sketch_stats node={@sup} />
            </div>
            <div class="flex items-center gap-1 rounded-tl rounded-br bg-base-200/60 px-2 py-1.5 text-xs inset-shadow-sm">
              <button
                type="button"
                class="flex items-center gap-1 rounded-md bg-base-100 px-2 py-1 font-semibold shadow-sm"
              >
                <.icon name="hero-bolt-micro" class="size-3.5" /> Action
              </button>
              <button
                type="button"
                class="rounded-md p-1 text-base-content/60 hover:bg-base-100 hover:text-base-content"
                title="Config"
              >
                <.icon name="hero-adjustments-horizontal-micro" class="size-3.5" />
              </button>
              <button
                type="button"
                class="rounded-md p-1 text-base-content/60 hover:bg-base-100 hover:text-base-content"
                title="Add"
              >
                <.icon name="hero-plus-micro" class="size-3.5" />
              </button>
              <span class="ml-auto font-mono text-[10px] text-base-content/40">{@sup.status.pid}</span>
            </div>
            <div class="flex flex-wrap items-center gap-1 rounded-br-xl border-t border-base-300 px-3 py-2.5">
              <.btn kind="danger">Kill</.btn>
              <.btn kind="warn">Stop</.btn>
              <.btn>Delete</.btn>
            </div>
          </div>
          <.handles />
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- C · Progressive disclosure --------------------------------------------

  attr :node, :map, required: true
  attr :open, :string, default: nil
  attr :strategies, :list, required: true
  attr :restarts, :list, required: true

  defp accordion_card(assigns) do
    assigns =
      assigns
      |> assign(:style, status_style(assigns.node.status))
      |> assign(:restart_count, restarts_of(assigns.node))

    ~H"""
    <div class="relative w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
      <div class={[
        "flex items-center gap-2 rounded-t-xl px-3 py-2",
        @node.kind == :supervisor && "bg-violet-50 dark:bg-violet-950/40",
        @node.kind == :genserver && "bg-sky-50 dark:bg-sky-950/40"
      ]}>
        <.dot status={@node.status} />
        <span class="truncate text-xs font-semibold">{@node.label}</span>
        <span class="ml-auto" /><.kind_badge node={@node} />
        <.order node={@node} />
      </div>
      <details class="group/s border-t border-base-300" open={@open == "status"}>
        <summary class="flex cursor-pointer select-none items-center gap-2 px-3 py-1.5 text-[11px]">
          <span class="font-medium text-base-content/70">Status</span>
          <span class={["ml-1 group-open/s:hidden", @style.text]}>{@style.label}</span>
          <span class="font-mono text-base-content/50 group-open/s:hidden">· {@restart_count} restarts</span>
          <.icon
            name="hero-chevron-down-micro"
            class="ml-auto size-3.5 text-base-content/40 transition-transform group-open/s:rotate-180"
          />
        </summary>
        <div class="px-3 pb-2"><.status_line node={@node} /></div>
      </details>
      <details class="group/c border-t border-base-300" open={@open == "config"}>
        <summary class="flex cursor-pointer select-none items-center gap-2 px-3 py-1.5 text-[11px]">
          <span class="font-medium text-base-content/70">Config</span>
          <span class="ml-1 font-mono text-base-content/70 group-open/c:hidden">
            {if @node.kind == :supervisor, do: @node.config.strategy, else: @node.config.restart}
          </span>
          <.icon
            name="hero-chevron-down-micro"
            class="ml-auto size-3.5 text-base-content/40 transition-transform group-open/c:rotate-180"
          />
        </summary>
        <div class="px-3 pb-2">
          <.config_control node={@node} strategies={@strategies} restarts={@restarts} />
        </div>
      </details>
      <details class="group/a border-t border-base-300" open={@open == "actions"}>
        <summary class="flex cursor-pointer select-none items-center gap-2 px-3 py-1.5 text-[11px]">
          <span class="font-medium text-base-content/70">Actions</span>
          <span class="ml-1 text-base-content/40 group-open/a:hidden">
            {if @node.kind == :supervisor,
              do: "add · kill · stop · delete",
              else: "crash · kill · stop · delete"}
          </span>
          <.icon
            name="hero-chevron-down-micro"
            class="ml-auto size-3.5 text-base-content/40 transition-transform group-open/a:rotate-180"
          />
        </summary>
        <div class="space-y-1 px-3 pb-2.5"><.action_buttons node={@node} /></div>
      </details>
      <.handles top={!@node.root} bottom={@node.kind == :supervisor} />
    </div>
    """
  end

  defp section_c(assigns) do
    ~H"""
    <Shared.section id="c" title="C · Progressive disclosure">
      <:intro>
        Show less by default, put the rest one click away. These differ in what stays visible and in
        where the hidden part appears: inside the card, floating over it, or beside the canvas.
      </:intro>

      <Shared.option
        code="C1"
        title="Accordion rows"
        wide
        note="Three collapsible rows: Status, Config, Actions. Each row's summary line shows its gist when closed, so a fully collapsed card still reads 'running · 2 restarts · one_for_all'. These are real details elements; click to try."
      >
        <div>
          <.accordion_card node={@sup} strategies={@strategies} restarts={@restarts} />
          <Shared.caption>All closed</Shared.caption>
        </div>
        <div>
          <.accordion_card node={@sup} open="status" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>Status open</Shared.caption>
        </div>
        <div>
          <.accordion_card node={@gen} open="actions" strategies={@strategies} restarts={@restarts} />
          <Shared.caption>GenServer, Actions open</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="C2"
        title="Kebab menu"
        class="min-h-80"
        note="The card keeps name, status, and config. Every action moves into a '⋯' menu, grouped as Add child / Process / Delete, with the underlying call as a hint. Drawn open; the real one would be a popover."
      >
        <div class="relative">
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <.order node={@sup} />
              <button type="button" class="ml-auto -mr-1 rounded-md bg-base-100 p-0.5 shadow-sm">
                <.icon name="hero-ellipsis-horizontal-micro" class="size-4" />
              </button>
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
            </div>
            <.handles />
          </div>
          <.action_menu node={@sup} class="absolute left-[15.5rem] top-7 z-10" />
        </div>
      </Shared.option>

      <Shared.option
        code="C3"
        title="Split button"
        class="min-h-[23rem]"
        note="One primary action stays visible with a chevron for the rest: Crash for a GenServer, + GenServer for a supervisor. The common move is one click, the rest two."
      >
        <div class="relative">
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <span class="ml-auto" /><.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@gen} />
              <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
              <div class="inline-flex pt-0.5">
                <button
                  type="button"
                  class="rounded-l-md border border-rose-300 px-2 py-0.5 text-[11px] font-medium text-rose-700 hover:bg-rose-50 dark:border-rose-800 dark:text-rose-300"
                >
                  Crash
                </button>
                <button
                  type="button"
                  class="-ml-px rounded-r-md border border-rose-300 bg-rose-50 px-1 text-rose-700 dark:border-rose-800 dark:bg-rose-950 dark:text-rose-300"
                >
                  <.icon name="hero-chevron-down-micro" class="size-3.5" />
                </button>
              </div>
            </div>
            <.handles bottom={false} />
          </div>
          <.action_menu node={@gen} class="absolute left-3 top-[10.75rem] z-10" />
        </div>
        <div class="relative">
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="ml-auto" /><.kind_badge node={@sup} />
              <.order node={@sup} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
              <div class="inline-flex pt-0.5">
                <button
                  type="button"
                  class="rounded-l-md border border-violet-300 px-2 py-0.5 text-[11px] font-medium text-violet-700 hover:bg-violet-50 dark:border-violet-700 dark:text-violet-300"
                >
                  + GenServer
                </button>
                <button
                  type="button"
                  class="-ml-px rounded-r-md border border-violet-300 px-1 text-violet-700 hover:bg-violet-50 dark:border-violet-700 dark:text-violet-300"
                >
                  <.icon name="hero-chevron-down-micro" class="size-3.5" />
                </button>
              </div>
            </div>
            <.handles />
          </div>
          <Shared.caption>Supervisor: closed</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="C4"
        title="Hover toolbar (NodeToolbar)"
        class="pt-14"
        note="ReactFlow's NodeToolbar: when a node is hovered or selected, an icon toolbar floats above it. The card itself is just facts. Tooltips carry the names. Icons: + sup, + gen | kill, stop, delete; bolt = crash."
      >
        <div class="relative">
          <div class="absolute -top-10 left-1/2 flex -translate-x-1/2 items-center gap-0.5 rounded-lg border border-base-300 bg-base-100 p-0.5 shadow-lg">
            <.action_icons node={@sup} />
          </div>
          <div class="relative w-60 rounded-xl border-2 border-violet-400 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-lg border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="ml-auto" /><.kind_badge node={@sup} />
              <.order node={@sup} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
            </div>
            <.handles />
          </div>
          <Shared.caption>Selected</Shared.caption>
        </div>
        <div class="relative">
          <div class="absolute -top-10 left-1/2 flex -translate-x-1/2 items-center gap-0.5 rounded-lg border border-base-300 bg-base-100 p-0.5 shadow-lg">
            <.action_icons node={@gen} />
          </div>
          <div class="relative w-60 rounded-xl border-2 border-sky-400 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-lg border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <span class="ml-auto" /><.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@gen} />
              <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
            </div>
            <.handles bottom={false} />
          </div>
          <Shared.caption>GenServer, selected</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="C5"
        title="Compact card + inspector panel"
        wide
        note="The node on the canvas is a one-glance summary. Selecting it fills an inspector beside the canvas (where the event log sits today) with everything: process facts, config, actions, and that node's recent events. Dense trees stay readable; the cost is that editing is always two steps away."
      >
        <div class="flex flex-wrap items-start gap-6">
          <div class="space-y-2">
            <div class="relative w-60 rounded-xl border-2 border-violet-400 bg-base-100 px-3 py-2 shadow-md">
              <div class="flex items-center gap-2">
                <.avatar node={@sup} class="size-7 text-[10px]" />
                <div class="min-w-0 flex-1">
                  <div class="truncate text-xs font-semibold">{@sup.label}</div>
                  <div class="flex items-center gap-1.5 whitespace-nowrap text-[10px] text-base-content/60">
                    <.dot status={@sup.status} class="size-1.5" />
                    <span>running</span>
                    <span class="font-mono">one_for_all</span>
                  </div>
                </div>
                <.order node={@sup} />
              </div>
              <.handles />
            </div>
            <Shared.caption>On the canvas, selected</Shared.caption>
          </div>
          <.icon name="hero-arrow-long-right" class="mt-4 size-6 text-base-content/30" />
          <div class="w-80 rounded-xl border border-base-300 bg-base-100 shadow-sm">
            <div class="flex items-center gap-3 border-b border-base-300 px-4 py-3">
              <.avatar node={@sup} />
              <div class="min-w-0">
                <div class="font-semibold">{@sup.label}</div>
                <div class="text-[11px] text-base-content/60">
                  Supervisor · child #2 of 3 under Application
                </div>
              </div>
              <.icon_btn name="hero-x-mark-micro" title="Close" class="ml-auto" />
            </div>
            <.inspector_section title="Process">
              <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-[11px]">
                <dt class="text-base-content/50">status</dt>
                <dd class="flex items-center gap-1.5 font-medium text-emerald-600 dark:text-emerald-400">
                  <.dot status={@sup.status} /> running
                </dd>
                <dt class="text-base-content/50">pid</dt>
                <dd class="font-mono">{@sup.status.pid}</dd>
                <dt class="text-base-content/50">restarts</dt>
                <dd class="font-mono">2</dd>
                <dt class="text-base-content/50">last exit</dt>
                <dd class="font-mono">:killed</dd>
              </dl>
            </.inspector_section>
            <.inspector_section title="Config">
              <.config_control
                node={@sup}
                strategies={@strategies}
                restarts={@restarts}
                control="segmented"
              />
            </.inspector_section>
            <.inspector_section title="Actions">
              <div class="space-y-1"><.action_buttons node={@sup} /></div>
            </.inspector_section>
            <.inspector_section title="Recent events">
              <ol class="space-y-1 text-[11px]">
                <li class="flex gap-2">
                  <.dot status={@sup.status} class="mt-1.5 size-1.5" /><span>started
                  <span class="font-mono text-base-content/60">#PID&lt;0.412.0&gt;</span></span><time class="ml-auto font-mono text-[10px] text-base-content/40">10:42:07</time>
                </li>
                <li class="flex gap-2">
                  <span class="mt-1.5 size-1.5 rounded-full bg-rose-500" /><span>exited
                  <span class="font-mono text-base-content/60">:killed</span></span><time class="ml-auto font-mono text-[10px] text-base-content/40">10:42:07</time>
                </li>
                <li class="flex gap-2">
                  <.dot status={@sup.status} class="mt-1.5 size-1.5" /><span>started
                  <span class="font-mono text-base-content/60">#PID&lt;0.398.0&gt;</span></span><time class="ml-auto font-mono text-[10px] text-base-content/40">10:41:50</time>
                </li>
              </ol>
            </.inspector_section>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="C6"
        title="Read-only card + modal"
        wide
        note="The card only reports. One 'Configure' link opens a modal with the whole form: config, the restart budget explained, and the actions with their consequences spelled out. Best when the explanation matters more than speed."
      >
        <div>
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="ml-auto" /><.kind_badge node={@sup} />
              <.order node={@sup} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <div class="text-[11px] text-base-content/60">
                strategy <span class="font-mono text-base-content">{@sup.config.strategy}</span>
              </div>
              <div class="flex items-center justify-between pt-0.5">
                <a href="#" class="text-[11px] font-medium text-primary hover:underline">Configure…</a>
                <a href="#" class="text-[11px] font-medium text-primary hover:underline">Actions…</a>
              </div>
            </div>
            <.handles />
          </div>
          <Shared.caption>Card</Shared.caption>
        </div>
        <div class="w-[26rem] rounded-xl border border-base-300 bg-base-100 shadow-2xl ring-8 ring-base-content/5">
          <div class="flex items-center gap-3 border-b border-base-300 px-5 py-3">
            <.avatar node={@sup} class="size-8 text-[11px]" />
            <div>
              <div class="font-semibold">{@sup.label}</div>
              <div class="text-[11px] text-base-content/60">Supervisor · {@sup.status.pid}</div>
            </div>
            <.icon_btn name="hero-x-mark-micro" title="Close" class="ml-auto" />
          </div>
          <div class="space-y-5 px-5 py-4 text-sm">
            <div class="space-y-2">
              <div class="text-xs font-semibold">Strategy</div>
              <div class="space-y-1.5">
                <label
                  :for={s <- @strategies}
                  class="flex items-start gap-2 rounded-md border border-base-300 px-3 py-2 text-xs has-[:checked]:border-violet-500 has-[:checked]:bg-violet-50 dark:has-[:checked]:bg-violet-950/40"
                >
                  <input
                    type="radio"
                    name="c6-strategy"
                    checked={s == @sup.config.strategy}
                    class="mt-0.5"
                  />
                  <span>
                    <span class="font-mono font-semibold">{s}</span>
                    <span class="block text-base-content/60">{strategy_help(s)}</span>
                  </span>
                </label>
              </div>
            </div>
            <div class="space-y-1">
              <div class="text-xs font-semibold">Restart budget</div>
              <p class="text-xs text-base-content/60">
                Gives up after <span class="font-mono text-base-content">3</span>
                restarts in <span class="font-mono text-base-content">5</span>
                seconds, then exits so its own parent restarts it.
              </p>
            </div>
            <div class="space-y-2">
              <div class="text-xs font-semibold">Actions</div>
              <div class="grid grid-cols-2 gap-2 text-xs">
                <button
                  type="button"
                  class="rounded-md border border-violet-300 px-3 py-2 text-left hover:bg-violet-50 dark:border-violet-700 dark:hover:bg-violet-950"
                >
                  <span class="font-medium text-violet-700 dark:text-violet-300">+ Supervisor</span>
                  <span class="block text-[11px] text-base-content/60">Add a child supervisor</span>
                </button>
                <button
                  type="button"
                  class="rounded-md border border-violet-300 px-3 py-2 text-left hover:bg-violet-50 dark:border-violet-700 dark:hover:bg-violet-950"
                >
                  <span class="font-medium text-violet-700 dark:text-violet-300">+ GenServer</span>
                  <span class="block text-[11px] text-base-content/60">Add a child GenServer</span>
                </button>
                <button
                  type="button"
                  class="rounded-md border border-rose-300 px-3 py-2 text-left hover:bg-rose-50 dark:border-rose-800 dark:hover:bg-rose-950"
                >
                  <span class="font-medium text-rose-700 dark:text-rose-300">Kill</span>
                  <span class="block font-mono text-[10px] text-base-content/60">Process.exit(pid, :kill)</span>
                </button>
                <button
                  type="button"
                  class="rounded-md border border-amber-300 px-3 py-2 text-left hover:bg-amber-50 dark:border-amber-800 dark:hover:bg-amber-950"
                >
                  <span class="font-medium text-amber-700 dark:text-amber-300">Stop</span>
                  <span class="block font-mono text-[10px] text-base-content/60">Supervisor.stop(pid, :normal)</span>
                </button>
              </div>
            </div>
          </div>
          <div class="flex items-center justify-between border-t border-base-300 px-5 py-3">
            <a href="#" class="text-xs text-rose-600 hover:underline dark:text-rose-300">Delete this supervisor and its subtree</a>
            <.btn kind="solid" class="px-3 py-1 text-xs">Done</.btn>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="C7"
        title="Right-click context menu"
        class="min-h-[26rem]"
        note="No buttons on the card at all; right-click (or long-press) anywhere on it for the menu, with config at the top of the same menu. Most invisible, least discoverable; a hint in the canvas corner would have to teach it."
      >
        <div class="relative">
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <span class="ml-auto" /><.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@gen} />
              <div class="text-[11px] text-base-content/60">
                restart <span class="font-mono text-base-content">{@gen.config.restart}</span>
              </div>
            </div>
            <.handles bottom={false} />
            <.icon
              name="hero-cursor-arrow-rays-micro"
              class="absolute left-28 top-16 size-4 text-base-content"
            />
          </div>
          <.action_menu
            node={@gen}
            with_config
            strategies={@strategies}
            restarts={@restarts}
            class="absolute left-32 top-[4.5rem] z-10 w-56"
          />
        </div>
      </Shared.option>

      <Shared.option
        code="C8"
        title="Collapsible card"
        note="Each card has a chevron: collapsed is one line (status dot, name, config value), expanded is the full example card. Collapse-all could be a canvas control, so a big tree can be read at a glance and one node opened to work on."
      >
        <div>
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-xl bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <.dot status={@sup.status} />
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="font-mono text-[10px] text-base-content/60">one_for_all</span>
              <span class="ml-auto font-mono text-[10px] text-base-content/50">2↻</span>
              <.icon name="hero-chevron-right-micro" class="size-3.5 text-base-content/50" />
            </div>
            <.handles />
          </div>
          <Shared.caption>Collapsed</Shared.caption>
        </div>
        <div>
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <.dot status={@sup.status} />
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="ml-auto" /><.order node={@sup} />
              <.icon name="hero-chevron-down-micro" class="size-3.5 text-base-content/50" />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
              <.action_buttons node={@sup} />
            </div>
            <.handles />
          </div>
          <Shared.caption>Expanded</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp inspector_section(assigns) do
    ~H"""
    <div class="border-b border-base-300 px-4 py-3 last:border-b-0">
      <div class="mb-2 text-[10px] font-semibold uppercase tracking-wide text-base-content/50">
        {@title}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- D · Config as inline controls ----------------------------------------

  defp section_d(assigns) do
    ~H"""
    <Shared.section id="d" title="D · Config as inline controls">
      <:intro>
        The select is the one editable thing on a card. These swap it for a control that also shows
        the alternatives, or that explains the current value, without opening anything.
      </:intro>

      <Shared.option
        code="D1"
        title="Segmented control"
        note="All three strategies visible, the active one raised. One click to change and no dropdown to open. Three monospace words need a 288px card at 10px, so the card is 48px wider than A2."
      >
        <.example_card node={@sup} strategies={@strategies} restarts={@restarts} control="segmented" />
        <.example_card node={@gen} strategies={@strategies} restarts={@restarts} control="segmented" />
      </Shared.option>

      <Shared.option
        code="D2"
        title="Radio chips with the definition underneath"
        note="Chips instead of a select, plus one line explaining the chosen value. Teaches as you click, which is the point of the playground."
      >
        <div class="relative w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
            <span class="truncate text-xs font-semibold">{@gen.label}</span>
            <span class="ml-auto" /><.kind_badge node={@gen} />
            <.order node={@gen} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@gen} />
            <div class="space-y-1">
              <div class="flex flex-wrap gap-1">
                <button
                  :for={r <- @restarts}
                  type="button"
                  class={[
                    "rounded-full border px-2 py-0.5 font-mono text-[10px] transition-colors",
                    r == @gen.config.restart &&
                      "border-sky-500 bg-sky-50 text-sky-700 dark:bg-sky-950 dark:text-sky-300",
                    r != @gen.config.restart &&
                      "border-base-300 text-base-content/60 hover:border-base-content/40"
                  ]}
                >
                  {r}
                </button>
              </div>
              <p class="text-[10px] leading-snug text-base-content/60">
                {restart_help(@gen.config.restart)}
              </p>
            </div>
            <.action_buttons node={@gen} />
          </div>
          <.handles bottom={false} />
        </div>
        <div class="relative w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
            <span class="truncate text-xs font-semibold">{@sup.label}</span>
            <span class="ml-auto" /><.kind_badge node={@sup} />
            <.order node={@sup} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@sup} />
            <div class="space-y-1">
              <div class="flex flex-wrap gap-1">
                <button
                  :for={s <- @strategies}
                  type="button"
                  class={[
                    "rounded-full border px-2 py-0.5 font-mono text-[10px] transition-colors",
                    s == @sup.config.strategy &&
                      "border-violet-500 bg-violet-50 text-violet-700 dark:bg-violet-950 dark:text-violet-300",
                    s != @sup.config.strategy &&
                      "border-base-300 text-base-content/60 hover:border-base-content/40"
                  ]}
                >
                  {s}
                </button>
              </div>
              <p class="text-[10px] leading-snug text-base-content/60">
                {strategy_help(@sup.config.strategy)} Gives up after 3 restarts in 5s.
              </p>
            </div>
            <.action_buttons node={@sup} />
          </div>
          <.handles />
        </div>
      </Shared.option>

      <Shared.option
        code="D3"
        title="Badge that opens a popover"
        class="min-h-72"
        note="The strategy is a clickable badge in the header; clicking it opens a popover listing the options with one-line definitions and a check on the current one. The card stays as quiet as a read-only one until you ask."
      >
        <div class="relative">
          <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <button
                type="button"
                class="ml-auto flex items-center gap-1 rounded-full border border-violet-300 bg-base-100 px-1.5 py-px font-mono text-[10px] text-violet-700 dark:border-violet-700 dark:text-violet-300"
              >
                one_for_all <.icon name="hero-chevron-down-micro" class="size-3" />
              </button>
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.action_buttons node={@sup} />
            </div>
            <.handles />
          </div>
          <div class="absolute left-[9rem] top-9 z-10 w-60 rounded-lg border border-base-300 bg-base-100 py-1 text-xs shadow-lg">
            <button
              :for={s <- @strategies}
              type="button"
              class="flex w-full items-start gap-2 px-3 py-1.5 text-left hover:bg-base-200"
            >
              <.icon
                name="hero-check-micro"
                class={["mt-0.5 size-3.5 shrink-0", s != @sup.config.strategy && "invisible"]}
              />
              <span>
                <span class="font-mono font-semibold">{s}</span>
                <span class="block text-[11px] text-base-content/60">{strategy_help(s)}</span>
              </span>
            </button>
            <div class="mt-1 border-t border-base-300 px-3 pt-1.5 text-[10px] text-base-content/50">
              Gives up after 3 restarts in 5s
            </div>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="D4"
        title="Config as code"
        note="Config drawn the way it is written in a child spec: key, value, pencil. The read-only budget sits alongside the editable strategy with no visual difference except the pencil. Reads well for people who know the API."
      >
        <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
            <span class="truncate text-xs font-semibold">{@sup.label}</span>
            <span class="ml-auto" /><.kind_badge node={@sup} />
            <.order node={@sup} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@sup} />
            <dl class="grid grid-cols-[auto_1fr_auto] items-center gap-x-2 gap-y-0.5 font-mono text-[11px]">
              <dt class="text-base-content/50">strategy:</dt>
              <dd class="text-violet-700 dark:text-violet-300">:one_for_all</dd>
              <dd><.icon_btn name="hero-pencil-square-micro" title="Edit" class="-my-1 p-0.5" /></dd>
              <dt class="text-base-content/50">max_restarts:</dt>
              <dd>3</dd>
              <dd />
              <dt class="text-base-content/50">max_seconds:</dt>
              <dd>5</dd>
              <dd />
            </dl>
            <.action_buttons node={@sup} />
          </div>
          <.handles />
        </div>
        <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
            <span class="truncate text-xs font-semibold">{@gen.label}</span>
            <span class="ml-auto" /><.kind_badge node={@gen} />
            <.order node={@gen} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@gen} />
            <dl class="grid grid-cols-[auto_1fr_auto] items-center gap-x-2 gap-y-0.5 font-mono text-[11px]">
              <dt class="text-base-content/50">restart:</dt>
              <dd class="text-sky-700 dark:text-sky-300">:permanent</dd>
              <dd><.icon_btn name="hero-pencil-square-micro" title="Edit" class="-my-1 p-0.5" /></dd>
            </dl>
            <.action_buttons node={@gen} />
          </div>
          <.handles bottom={false} />
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- E · Status emphasis ---------------------------------------------------

  defp section_e(assigns) do
    ~H"""
    <Shared.section id="e" title="E · Status emphasis">
      <:intro>
        The playground is about watching processes die and come back, so status is the thing that
        changes. These make the state and the restart count the loudest thing on the card.
      </:intro>

      <Shared.option
        code="E1"
        title="Status stripe + big restart count"
        note="A coloured left edge carries the state; the restart count is the biggest number on the card with the last exit reason as its caption. Scanning a tree you see colour and digits first."
      >
        <div :for={state <- [:running, :down]} class="relative">
          <div class={[
            "relative w-60 rounded-xl border border-l-4 border-base-300 bg-base-100 shadow-md",
            status_style(with_state(@gen, state).status).stripe
          ]}>
            <div class="flex items-center gap-2 px-3 pt-2">
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <span class="ml-auto" /><.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <div class="flex items-end gap-3 px-3 py-2">
              <div>
                <div class="text-3xl font-semibold leading-none tabular-nums">1</div>
                <div class="mt-1 text-[10px] uppercase tracking-wide text-base-content/50">
                  restarts
                </div>
              </div>
              <div class="min-w-0 flex-1 pb-0.5 text-[11px]">
                <div class={["font-medium", status_style(with_state(@gen, state).status).text]}>
                  {status_style(with_state(@gen, state).status).label}
                </div>
                <div
                  class="truncate font-mono text-[10px] text-base-content/60"
                  title={@gen.status.last_exit}
                >
                  {@gen.status.last_exit}
                </div>
                <div class="font-mono text-[10px] text-base-content/40">{@gen.status.pid}</div>
              </div>
            </div>
            <div class="space-y-2 border-t border-base-300 px-3 py-2">
              <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
              <.action_buttons node={@gen} />
            </div>
            <.handles bottom={false} />
          </div>
          <Shared.caption>{state}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="E2"
        title="Header tinted by state"
        wide
        note="The header's tint is the state, not the kind: green running, amber (pulsing) starting, red down, grey dashed when not supervised. Kind moves to the badge only. All four states of one card."
      >
        <div :for={state <- [:running, :starting, :down, :none]}>
          <% node = with_state(@gen, state) %>
          <% style = status_style(node.status) %>
          <div class={[
            "relative w-56 rounded-xl border bg-base-100 shadow-md",
            node.attached && "border-base-300",
            !node.attached && "border-dashed border-base-content/30"
          ]}>
            <div class={[
              "flex items-center gap-2 rounded-t-xl border-b border-base-300 px-3 py-1.5",
              style.tint
            ]}>
              <.dot status={node.status} />
              <span class="truncate text-xs font-semibold">{node.label}</span>
              <span class={["ml-auto text-[10px] font-medium", style.text]}>
                {if node.attached, do: style.label, else: "unsupervised"}
              </span>
            </div>
            <div class="space-y-2 px-3 py-2">
              <div class="flex items-center gap-2 text-[11px] text-base-content/60">
                <.kind_badge node={node} />
                <.order node={node} />
                <span :if={node.attached} class="ml-auto font-mono text-[10px]">{node.status.pid}</span>
              </div>
              <div :if={node.attached} class="text-[11px] text-base-content/60">
                restarts <span class="font-mono text-base-content">{restarts_of(node)}</span>
                <span :if={node.status.last_exit} class="ml-2">last
                <span class="font-mono text-base-content">{node.status.last_exit}</span></span>
              </div>
              <div :if={!node.attached} class="text-[11px] text-base-content/50">
                Connect it to a supervisor to start it.
              </div>
              <.config_control node={node} strategies={@strategies} restarts={@restarts} />
              <.action_buttons node={node} />
            </div>
            <.handles bottom={false} />
          </div>
          <Shared.caption>{if state == :none, do: "not supervised", else: state}</Shared.caption>
        </div>
      </Shared.option>

      <Shared.option
        code="E3"
        title="Lifecycle dots"
        note="The last ten start/exit events as a row of tiny dots, newest on the right, with a sentence under it. A node that has been bouncing shows as a red-green barcode; a healthy one is a single green dot."
      >
        <div class="relative w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
            <span class="truncate text-xs font-semibold">{@gen.label}</span>
            <span class="ml-auto" /><.kind_badge node={@gen} />
            <.order node={@gen} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <div class="space-y-1">
              <div class="flex items-center gap-1">
                <span
                  :for={k <- [:s, :x, :s, :x, :s, :x, :s]}
                  class={[
                    "size-2 rounded-full",
                    k == :s && "bg-emerald-500",
                    k == :x && "bg-rose-500"
                  ]}
                />
                <span :for={_ <- 1..3} class="size-2 rounded-full border border-base-300" />
                <span class="ml-auto font-mono text-[10px] text-base-content/40">{@gen.status.pid}</span>
              </div>
              <p class="text-[11px] text-base-content/70">
                <span class="font-medium text-emerald-600 dark:text-emerald-400">running</span>, restarted
                <span class="font-mono text-base-content">3</span>
                times, last exit <span class="font-mono text-base-content">boom</span>
                4s ago
              </p>
            </div>
            <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
            <.action_buttons node={@gen} />
          </div>
          <.handles bottom={false} />
        </div>
      </Shared.option>

      <Shared.option
        code="E4"
        title="Avatar ring is the status"
        note="The sketch's avatar, with its ring colour doing the status work (and pulsing while starting). Frees the body from a status line; the pid and restart count become a quiet second line under the name."
      >
        <div :for={state <- [:running, :starting, :down, :none]}>
          <% node = with_state(@sup, state) %>
          <div class="relative flex w-72 items-start gap-3 rounded-xl border border-base-300 bg-base-100 p-3 shadow-sm">
            <.avatar
              node={node}
              class={[
                "size-10 text-xs ring-2 ring-offset-2 ring-offset-base-100",
                status_style(node.status).ring
              ]}
            />
            <div class="min-w-0 flex-1">
              <div class="flex items-baseline gap-2">
                <h3 class="truncate font-semibold">{node.label}</h3>
                <.order node={node} />
                <.icon_btn
                  name="hero-ellipsis-horizontal-micro"
                  title="More"
                  class="-mr-2 -mt-1 ml-auto"
                />
              </div>
              <div class="text-[11px] text-base-content/60">
                <span :if={node.attached}>
                  <span class={["font-medium", status_style(node.status).text]}>{status_style(node.status).label}</span>
                  · <span class="font-mono">{restarts_of(node)}</span>
                  restarts · <span class="font-mono">{node.status.pid}</span>
                </span>
                <span :if={!node.attached}>not supervised, so not running</span>
              </div>
              <div class="mt-2">
                <.config_control node={node} strategies={@strategies} restarts={@restarts} />
              </div>
            </div>
            <.handles />
          </div>
          <Shared.caption>{if state == :none, do: "not supervised", else: state}</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- F · Shape and tone ----------------------------------------------------

  defp section_f(assigns) do
    ~H"""
    <Shared.section id="f" title="F · Shape and tone">
      <:intro>
        Different silhouettes on the canvas. Some trade the card for a chip or a circle so a large
        tree fits; one borrows the look of an iex session.
      </:intro>

      <Shared.option
        code="F1"
        title="Chip"
        note="A single row: dot, name, config value, restart count, menu. Four or five chips fit where one example card does. Everything else is in the menu or an inspector (C5)."
      >
        <div class="space-y-3">
          <div class="relative inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-100 py-1 pl-2.5 pr-1 shadow-md">
            <.dot status={@sup.status} />
            <span class="text-xs font-semibold">{@sup.label}</span>
            <span class="rounded-full bg-violet-50 px-1.5 font-mono text-[10px] text-violet-700 dark:bg-violet-950 dark:text-violet-300">one_for_all</span>
            <span class="font-mono text-[10px] text-base-content/50">2↻</span>
            <.icon_btn name="hero-ellipsis-horizontal-micro" title="More" class="p-0.5" />
            <.handles />
          </div>
          <div class="relative inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-100 py-1 pl-2.5 pr-1 shadow-md">
            <.dot status={@gen.status} />
            <span class="text-xs font-semibold">{@gen.label}</span>
            <span class="rounded-full bg-sky-50 px-1.5 font-mono text-[10px] text-sky-700 dark:bg-sky-950 dark:text-sky-300">permanent</span>
            <span class="font-mono text-[10px] text-base-content/50">1↻</span>
            <.icon_btn name="hero-ellipsis-horizontal-micro" title="More" class="p-0.5" />
            <.handles bottom={false} />
          </div>
          <div class="relative inline-flex items-center gap-2 rounded-full border border-dashed border-base-content/30 bg-base-100 py-1 pl-2.5 pr-1 opacity-80">
            <span class="size-2 rounded-full border border-dashed border-base-content/40" />
            <span class="text-xs font-semibold">GenServer 5</span>
            <span class="rounded-full bg-sky-50 px-1.5 font-mono text-[10px] text-sky-700 dark:bg-sky-950 dark:text-sky-300">transient</span>
            <.icon_btn name="hero-ellipsis-horizontal-micro" title="More" class="p-0.5" />
            <.handles bottom={false} />
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="F2"
        title="Circle node"
        class="pt-10"
        note="The process as a circle, the way supervision trees are drawn in books: ring is status, letters are kind, name and config underneath. Actions appear as a ring of icons on hover. Edges attach to the circle itself."
      >
        <div class="flex flex-col items-center">
          <div class="relative">
            <div class="absolute -top-9 left-1/2 flex -translate-x-1/2 items-center gap-0.5 rounded-full border border-base-300 bg-base-100 p-0.5 shadow-lg">
              <.action_icons node={@sup} />
            </div>
            <div class="flex size-16 items-center justify-center rounded-full bg-base-content text-sm font-semibold text-base-100 shadow-md ring-4 ring-emerald-500 ring-offset-2 ring-offset-base-100">
              su
            </div>
            <span class="absolute -right-1 -top-1 rounded-full bg-base-100 px-1.5 font-mono text-[10px] text-base-content/70 shadow">2↻</span>
          </div>
          <div class="mt-3 text-center">
            <div class="text-xs font-semibold">{@sup.label}</div>
            <div class="font-mono text-[10px] text-base-content/60">one_for_all · #2/3</div>
          </div>
          <Shared.caption>Hovered</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <div class="flex size-14 items-center justify-center rounded-full bg-sky-600 text-sm font-semibold text-white shadow-md ring-4 ring-rose-500 ring-offset-2 ring-offset-base-100">
            gs
          </div>
          <div class="mt-3 text-center">
            <div class="text-xs font-semibold">{@gen.label}</div>
            <div class="font-mono text-[10px] text-base-content/60">permanent · down</div>
          </div>
          <Shared.caption>GenServer, down</Shared.caption>
        </div>
        <div class="flex flex-col items-center">
          <div class="flex size-14 items-center justify-center rounded-full border-2 border-dashed border-base-content/40 bg-base-100 text-sm font-semibold text-base-content/50">
            gs
          </div>
          <div class="mt-3 text-center">
            <div class="text-xs font-semibold text-base-content/60">GenServer 5</div>
            <div class="font-mono text-[10px] text-base-content/50">unsupervised</div>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="F3"
        title="iex style"
        note="A monospace card that looks like what iex would print for this process, with the actions written as the calls they make. Fits the audience exactly; the trade is that it is busier than prose."
      >
        <div class="relative w-72 rounded-lg border border-stone-700 bg-stone-900 px-3 py-2 font-mono text-[11px] leading-relaxed text-stone-300 shadow-md">
          <div class="flex items-center gap-2">
            <span class="text-emerald-400">●</span>
            <span class="font-semibold text-stone-100">{@sup.label}</span>
            <span class="text-stone-500">{@sup.status.pid}</span>
            <span class="ml-auto text-stone-500">#2/3</span>
          </div>
          <div class="mt-1 text-stone-400">
            strategy: <span class="text-violet-300">:one_for_all</span>
            ▾<br /> max_restarts: <span class="text-stone-200">3</span>, max_seconds:
            <span class="text-stone-200">5</span><br /> restarts: <span class="text-stone-200">2</span>, last_exit:
            <span class="text-rose-300">:killed</span>
          </div>
          <div class="mt-2 flex flex-wrap gap-x-3 gap-y-1 border-t border-stone-700 pt-1.5">
            <a href="#" class="text-rose-300 hover:underline">Process.exit(:kill)</a>
            <a href="#" class="text-amber-300 hover:underline">Supervisor.stop</a>
            <a href="#" class="text-violet-300 hover:underline">+ Supervisor</a>
            <a href="#" class="text-violet-300 hover:underline">+ GenServer</a>
            <a href="#" class="text-stone-500 hover:underline">delete</a>
          </div>
          <.handles />
        </div>
        <div class="relative w-72 rounded-lg border border-stone-700 bg-stone-900 px-3 py-2 font-mono text-[11px] leading-relaxed text-stone-300 shadow-md">
          <div class="flex items-center gap-2">
            <span class="text-emerald-400">●</span>
            <span class="font-semibold text-stone-100">{@gen.label}</span>
            <span class="text-stone-500">{@gen.status.pid}</span>
            <span class="ml-auto text-stone-500">#3/3</span>
          </div>
          <div class="mt-1 text-stone-400">
            restart: <span class="text-sky-300">:permanent</span>
            ▾<br /> restarts: <span class="text-stone-200">1</span>, last_exit:
            <span class="text-rose-300">(RuntimeError) boom</span>
          </div>
          <div class="mt-2 flex flex-wrap gap-x-3 gap-y-1 border-t border-stone-700 pt-1.5">
            <a href="#" class="text-rose-300 hover:underline">raise</a>
            <a href="#" class="text-rose-300 hover:underline">Process.exit(:kill)</a>
            <a href="#" class="text-amber-300 hover:underline">exit(:normal)</a>
            <a href="#" class="text-stone-500 hover:underline">delete</a>
          </div>
          <.handles bottom={false} />
        </div>
      </Shared.option>

      <Shared.option
        code="F4"
        title="Facts left, action rail right"
        note="Two columns: everything you read on the left, a vertical rail of icon buttons on the right edge. The rail is the same for every card so hands learn it; the card stays short."
      >
        <div class="relative flex w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="min-w-0 flex-1 space-y-2 px-3 py-2">
            <div class="flex items-center gap-2">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <.kind_badge node={@sup} />
              <.order node={@sup} />
            </div>
            <.status_line node={@sup} />
            <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
          </div>
          <div class="flex flex-col items-center gap-0.5 rounded-r-xl border-l border-base-300 bg-base-200/50 px-1 py-1.5">
            <.icon_btn name="hero-plus-micro" tone="add" title="Add a child supervisor" />
            <.icon_btn name="hero-plus-circle-micro" tone="add" title="Add a child GenServer" />
            <span class="my-0.5 h-px w-4 bg-base-300" />
            <.icon_btn name="hero-x-mark-micro" tone="danger" title="Kill" />
            <.icon_btn name="hero-stop-micro" tone="warn" title="Stop" />
            <span class="my-0.5 h-px w-4 bg-base-300" />
            <.icon_btn name="hero-trash-micro" title="Delete" />
          </div>
          <.handles />
        </div>
        <div class="relative flex w-64 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="min-w-0 flex-1 space-y-2 px-3 py-2">
            <div class="flex items-center gap-2">
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <.status_line node={@gen} />
            <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
          </div>
          <div class="flex flex-col items-center gap-0.5 rounded-r-xl border-l border-base-300 bg-base-200/50 px-1 py-1.5">
            <.icon_btn name="hero-bolt-micro" tone="danger" title="Crash" />
            <.icon_btn name="hero-x-mark-micro" tone="danger" title="Kill" />
            <.icon_btn name="hero-stop-micro" tone="warn" title="Stop" />
            <span class="my-0.5 h-px w-4 bg-base-300" />
            <.icon_btn name="hero-trash-micro" title="Delete" />
          </div>
          <.handles bottom={false} />
        </div>
      </Shared.option>

      <Shared.option
        code="F5"
        title="Icon toolbar along the bottom edge"
        note="The example card with its two rows of text buttons replaced by one row of icons in a footer strip. Same reach, a third of the height. Needs tooltips; a legend in the cheat sheet would help."
      >
        <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
            <span class="truncate text-xs font-semibold">{@sup.label}</span>
            <span class="ml-auto" /><.kind_badge node={@sup} />
            <.order node={@sup} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@sup} />
            <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
          </div>
          <div class="flex items-center justify-center gap-0.5 rounded-b-xl border-t border-base-300 bg-base-200/50 px-2 py-1">
            <.action_icons node={@sup} />
          </div>
          <.handles />
        </div>
        <div class="relative w-60 rounded-xl border border-base-300 bg-base-100 shadow-md">
          <div class="flex items-center gap-2 rounded-t-xl border-b border-base-300 bg-sky-50 px-3 py-1.5 dark:bg-sky-950/40">
            <span class="truncate text-xs font-semibold">{@gen.label}</span>
            <span class="ml-auto" /><.kind_badge node={@gen} />
            <.order node={@gen} />
          </div>
          <div class="space-y-2 px-3 py-2">
            <.status_line node={@gen} />
            <.config_control node={@gen} strategies={@strategies} restarts={@restarts} />
          </div>
          <div class="flex items-center justify-center gap-0.5 rounded-b-xl border-t border-base-300 bg-base-200/50 px-2 py-1">
            <.action_icons node={@gen} />
          </div>
          <.handles bottom={false} />
        </div>
      </Shared.option>

      <Shared.option
        code="F6"
        title="Floating dock beside the card"
        note="Actions in a pill that hangs off the card's right edge, outside its border, and only when selected. The card is pure facts; the dock does not change the card's size so the tree layout never shifts."
      >
        <div class="relative mr-10">
          <div class="relative w-60 rounded-xl border-2 border-violet-400 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-lg border-b border-base-300 bg-violet-50 px-3 py-1.5 dark:bg-violet-950/40">
              <span class="truncate text-xs font-semibold">{@sup.label}</span>
              <span class="ml-auto" /><.kind_badge node={@sup} />
              <.order node={@sup} />
            </div>
            <div class="space-y-2 px-3 py-2">
              <.status_line node={@sup} />
              <.config_control node={@sup} strategies={@strategies} restarts={@restarts} />
            </div>
            <.handles />
          </div>
          <div class="absolute -right-10 top-1/2 flex -translate-y-1/2 flex-col items-center gap-0.5 rounded-full border border-base-300 bg-base-100 p-1 shadow-lg">
            <.icon_btn
              name="hero-plus-micro"
              tone="add"
              title="Add a child supervisor"
              class="rounded-full"
            />
            <.icon_btn
              name="hero-plus-circle-micro"
              tone="add"
              title="Add a child GenServer"
              class="rounded-full"
            />
            <.icon_btn name="hero-x-mark-micro" tone="danger" title="Kill" class="rounded-full" />
            <.icon_btn name="hero-stop-micro" tone="warn" title="Stop" class="rounded-full" />
            <.icon_btn name="hero-trash-micro" title="Delete" class="rounded-full" />
          </div>
          <Shared.caption>Selected</Shared.caption>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end

  # -- G · Combinations ------------------------------------------------------

  defp section_g(assigns) do
    ~H"""
    <Shared.section id="g" title="G · Combinations">
      <:intro>
        A few of the above put together, as candidates for the next round.
      </:intro>

      <Shared.option
        code="G1"
        title="Sketch + status ring + kebab + segmented"
        note="A1's silhouette with E4's ring on the avatar, D1's segmented control on the config line, and C2's menu for actions. Nothing to click to read it; one click for any edit; two for any action."
      >
        <div class="relative">
          <.sketch_card
            node={@sup}
            avatar_ring
            menu
            control="segmented"
            class="w-[22rem]"
            strategies={@strategies}
            restarts={@restarts}
          />
        </div>
        <div class="relative">
          <.sketch_card
            node={@gen}
            avatar_ring
            menu
            control="segmented"
            class="w-[22rem]"
            strategies={@strategies}
            restarts={@restarts}
          />
        </div>
      </Shared.option>

      <Shared.option
        code="G2"
        title="Chip on the canvas + inspector off it"
        note="F1 and C5 together. The canvas is a diagram of chips, readable at any size; the inspector beside it does all the work for whichever one is selected. Keyboard arrows could move the selection down the tree."
      >
        <div class="flex items-start gap-6">
          <div class="relative space-y-4 pl-2">
            <div class="relative inline-flex items-center gap-2 rounded-full border-2 border-violet-400 bg-base-100 py-1 pl-2.5 pr-3 shadow-md">
              <.dot status={@sup.status} />
              <span class="text-xs font-semibold">{@sup.label}</span>
              <span class="font-mono text-[10px] text-base-content/50">one_for_all</span>
              <.handles />
            </div>
            <div class="ml-6 space-y-3">
              <div class="relative inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-100 py-1 pl-2.5 pr-3 shadow-md">
                <.dot status={@gen.status} />
                <span class="text-xs font-semibold">GenServer 3</span>
                <span class="font-mono text-[10px] text-base-content/50">permanent</span>
                <.handles bottom={false} />
              </div>
              <br />
              <div class="relative inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-100 py-1 pl-2.5 pr-3 shadow-md">
                <.dot status={with_state(@gen, :down).status} />
                <span class="text-xs font-semibold">{@gen.label}</span>
                <span class="font-mono text-[10px] text-base-content/50">permanent</span>
                <span class="font-mono text-[10px] text-rose-500">1↻</span>
                <.handles bottom={false} />
              </div>
            </div>
          </div>
          <div class="w-64 rounded-xl border border-base-300 bg-base-100 shadow-sm">
            <div class="flex items-center gap-2 border-b border-base-300 px-3 py-2">
              <.avatar node={@sup} class="size-7 text-[10px]" />
              <div class="min-w-0">
                <div class="truncate text-xs font-semibold">{@sup.label}</div>
                <div class="text-[10px] text-base-content/60">Supervisor · #2/3</div>
              </div>
            </div>
            <.inspector_section title="Process">
              <.status_line node={@sup} />
            </.inspector_section>
            <.inspector_section title="Config">
              <.config_control
                node={@sup}
                strategies={@strategies}
                restarts={@restarts}
                control="segmented"
              />
            </.inspector_section>
            <.inspector_section title="Actions">
              <div class="space-y-1"><.action_buttons node={@sup} /></div>
            </.inspector_section>
          </div>
        </div>
      </Shared.option>

      <Shared.option
        code="G3"
        title="Example card + icon footer + segmented"
        note="The smallest step from where we are: keep A2's structure, swap the select for D1's segmented control, and the two button rows for F5's icon strip. Same information, about 40% shorter."
      >
        <.example_card node={@sup} strategies={@strategies} restarts={@restarts} control="segmented">
          <div class="-mx-3 -mb-2 flex items-center justify-center gap-0.5 rounded-b-xl border-t border-base-300 bg-base-200/50 px-2 py-1">
            <.action_icons node={@sup} />
          </div>
        </.example_card>
        <.example_card node={@gen} strategies={@strategies} restarts={@restarts} control="segmented">
          <div class="-mx-3 -mb-2 flex items-center justify-center gap-0.5 rounded-b-xl border-t border-base-300 bg-base-200/50 px-2 py-1">
            <.action_icons node={@gen} />
          </div>
        </.example_card>
      </Shared.option>

      <Shared.option
        code="G4"
        title="Collapsible accordion with a hover toolbar"
        note="C1's accordion for reading (summaries carry the gist when closed) and C4's floating toolbar for acting, so the Actions row disappears from the card entirely. Try opening the rows."
      >
        <div class="relative pt-10">
          <div class="absolute left-1/2 top-0 flex -translate-x-1/2 items-center gap-0.5 rounded-lg border border-base-300 bg-base-100 p-0.5 shadow-lg">
            <.action_icons node={@gen} />
          </div>
          <div class="relative w-64 rounded-xl border-2 border-sky-400 bg-base-100 shadow-md">
            <div class="flex items-center gap-2 rounded-t-lg bg-sky-50 px-3 py-2 dark:bg-sky-950/40">
              <.dot status={@gen.status} />
              <span class="truncate text-xs font-semibold">{@gen.label}</span>
              <span class="ml-auto" /><.kind_badge node={@gen} />
              <.order node={@gen} />
            </div>
            <details class="group/s border-t border-base-300" open>
              <summary class="flex cursor-pointer select-none items-center gap-2 px-3 py-1.5 text-[11px]">
                <span class="font-medium text-base-content/70">Status</span>
                <span class="ml-1 text-emerald-600 group-open/s:hidden dark:text-emerald-400">running</span>
                <span class="font-mono text-base-content/50 group-open/s:hidden">· 1 restart</span>
                <.icon
                  name="hero-chevron-down-micro"
                  class="ml-auto size-3.5 text-base-content/40 transition-transform group-open/s:rotate-180"
                />
              </summary>
              <div class="px-3 pb-2"><.status_line node={@gen} /></div>
            </details>
            <details class="group/c rounded-b-lg border-t border-base-300">
              <summary class="flex cursor-pointer select-none items-center gap-2 px-3 py-1.5 text-[11px]">
                <span class="font-medium text-base-content/70">Config</span>
                <span class="ml-1 font-mono text-base-content/70 group-open/c:hidden">permanent</span>
                <.icon
                  name="hero-chevron-down-micro"
                  class="ml-auto size-3.5 text-base-content/40 transition-transform group-open/c:rotate-180"
                />
              </summary>
              <div class="px-3 pb-2">
                <.config_control
                  node={@gen}
                  strategies={@strategies}
                  restarts={@restarts}
                  control="segmented"
                />
              </div>
            </details>
            <.handles bottom={false} />
          </div>
        </div>
      </Shared.option>
    </Shared.section>
    """
  end
end
