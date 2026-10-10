// The process card: the settled design from /explorations/process-cards-round-three
// (Q1 / P1). A stacked header with a dark icon disc and a corner status dot,
// a stats row, and a tab-bar footer that opens a grey drawer below itself.
//
// Colour means status and nothing else. The kind lives in the icon and the
// subtitle's first word, both neutral.
//
// Everything here is presentational. The card owns one piece of local state,
// which tab is open, and takes everything else as props so it can be reused
// for supervisors, GenServers, and later GenStage stages.
import {useState} from "react"

// Hero icon classes must appear literally in source, or Tailwind never
// generates them and the icon renders blank. Never build them by
// concatenation.
export const KIND_ICONS = {
  supervisor: "hero-square-3-stack-3d-mini",
  genserver: "hero-cube-mini",
}

export const STATE_STYLES = {
  running: {
    dot: "bg-emerald-500",
    text: "text-emerald-600 dark:text-emerald-400",
    label: "running",
  },
  starting: {
    dot: "bg-amber-400 animate-pulse",
    text: "text-amber-600 dark:text-amber-400",
    label: "starting",
  },
  down: {
    dot: "bg-rose-500",
    text: "text-rose-600 dark:text-rose-400",
    label: "down",
  },
  none: {
    dot: "bg-base-100 border-2 border-dashed border-base-content/40",
    text: "text-base-content/50",
    label: "not supervised",
  },
}

export const TABS = [
  {id: "action", label: "Action", icon: "hero-bolt-micro"},
  {id: "config", label: "Config", icon: "hero-adjustments-horizontal-micro"},
  {id: "add", label: "Add", icon: "hero-plus-micro"},
  {id: "logs", label: "Logs", icon: "hero-list-bullet-micro"},
]

const GRID_COLS = {3: "grid-cols-3", 4: "grid-cols-4", 5: "grid-cols-5"}

export function stateStyle(state) {
  return STATE_STYLES[state] ?? STATE_STYLES.none
}

// A hero icon. `name` must be a literal class name (see KIND_ICONS).
export function Icon({name, className = ""}) {
  return <span className={`${name} ${className}`} aria-hidden="true" />
}

// The avatar: the kind's icon on a dark disc, status dot on the lower-right.
export function Avatar({icon, state = "none", size = "size-10"}) {
  const style = stateStyle(state)

  return (
    <span className="relative inline-flex shrink-0">
      <span className={`inline-flex items-center justify-center rounded-full bg-base-content text-base-100 ${size}`}>
        <Icon name={icon} className="size-5" />
      </span>
      <span className={`absolute -bottom-0.5 -right-0.5 size-3.5 rounded-full ring-2 ring-base-100 ${style.dot}`} />
    </span>
  )
}

// The header: avatar left, title and child order on one line, kind name and
// config summary below.
export function CardHeader({icon, state, label, order, kindName, subtitle}) {
  return (
    <div className="flex items-center gap-3 px-4 pb-2 pt-3">
      <Avatar icon={icon} state={state} />
      <div className="min-w-0 flex-1">
        <div className="flex items-baseline gap-2">
          <h3 className="truncate font-semibold">{label}</h3>
          {order && <span className="font-mono text-[10px] text-base-content/50">{order}</span>}
        </div>
        <p className="truncate text-xs text-base-content/60" title={subtitle ? `${kindName} · ${subtitle}` : undefined}>
          {kindName}
          {subtitle && <> · {subtitle}</>}
        </p>
      </div>
    </div>
  )
}

function Stat({label, className = "", title, children}) {
  return (
    <div className={className}>
      <div className="text-[10px] uppercase tracking-wide text-base-content/40">{label}</div>
      <div className="truncate" title={title}>
        {children}
      </div>
    </div>
  )
}

// Status, restarts, pid. The one place the status word appears. The pid is
// identity rather than a reading, so it takes the subtitle's quieter style.
export function StatsRow({state = "none", restarts, pid}) {
  const style = stateStyle(state)
  const supervised = state !== "none"

  return (
    <div className="flex gap-6 text-sm">
      <Stat label="Status">
        <span className={`whitespace-nowrap font-medium ${style.text}`}>{style.label}</span>
      </Stat>
      <Stat label="Restarts">
        <span className="font-mono">{supervised ? (restarts ?? 0) : "–"}</span>
      </Stat>
      <Stat label="PID" className="min-w-0" title={pid ?? undefined}>
        <span className="font-mono text-xs text-base-content/60">{pid || "–"}</span>
      </Stat>
    </div>
  )
}

// The footer: K3's tab bar. Every label visible, the active tab darker.
// Clicking the active tab again closes the drawer.
export function TabBar({tabs, active, onSelect, open}) {
  const cols = GRID_COLS[tabs.length] ?? "grid-cols-4"

  return (
    <div
      className={[
        "grid overflow-hidden bg-stone-200/40 dark:bg-stone-800/40",
        cols,
        open ? "" : "rounded-b-xl",
      ].join(" ")}
      role="tablist"
    >
      {tabs.map(tab => {
        const selected = tab.id === active
        return (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={selected}
            onClick={() => onSelect(selected ? null : tab.id)}
            className={[
              "nodrag nopan flex flex-col items-center gap-0.5 py-1.5 text-[10px] transition-colors",
              selected ? "font-semibold text-base-content" : "text-base-content/50 hover:text-base-content",
            ].join(" ")}
          >
            <Icon name={tab.icon} className="size-4" />
            {tab.label}
          </button>
        )
      })}
    </div>
  )
}

// What a tab opens: a grey drawer below the tab bar, continuous with it, so
// the tab bar and its panel read as one block at the bottom of the card. A
// hairline separates tabs from content.
export function Drawer({children}) {
  return (
    <div className="nodrag nopan rounded-b-xl border-t border-base-content/10 bg-stone-200/40 px-4 py-3 dark:bg-stone-800/40">
      {children}
    </div>
  )
}

/**
 * ProcessCard
 *
 *   icon       hero icon class for the kind (see KIND_ICONS)
 *   label      "Supervisor 2"
 *   order      "#2/3", start order under the parent, optional
 *   kindName   "Supervisor" | "GenServer"
 *   subtitle   config summary, e.g. "one_for_all · permanent · gives up after 3 in 5s"
 *   state      "running" | "starting" | "down" | "none"
 *   restarts   number
 *   pid        "#PID<0.332.0>" | null
 *   tabs       which of TABS to show, defaults to all four
 *   panels     {tabId: ReactNode | ({close}) => ReactNode} rendered in the
 *              drawer when that tab is open; the function form gets `close`
 *              so a panel can shut the drawer once its job is done
 *   children   anything to overlay on the card, such as ReactFlow handles
 */
export function ProcessCard({
  icon,
  label,
  order,
  kindName,
  subtitle,
  state = "none",
  restarts = 0,
  pid = null,
  tabs = TABS,
  panels = {},
  className = "w-76",
  children,
}) {
  const [active, setActive] = useState(null)
  const open = active != null && active in panels
  const close = () => setActive(null)
  const panel = open && (typeof panels[active] === "function" ? panels[active]({close}) : panels[active])

  return (
    <div className={`relative rounded-xl border border-base-300 bg-base-100 shadow-sm ${className}`}>
      <CardHeader icon={icon} state={state} label={label} order={order} kindName={kindName} subtitle={subtitle} />

      <div className="px-4 pb-3">
        <StatsRow state={state} restarts={restarts} pid={pid} />
      </div>

      <TabBar tabs={tabs} active={open ? active : null} onSelect={setActive} open={open} />

      {open && <Drawer>{panel}</Drawer>}

      {children}
    </div>
  )
}
