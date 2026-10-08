// What each tab opens. The Add panel is built; the others are placeholders
// sketching the shape of each panel from the exploration so the drawer has
// something to show. Nothing but Add is wired up yet.

function Placeholder({children}) {
  return <p className="text-[11px] leading-snug text-base-content/60">{children}</p>
}

export function ActionPanel({actions = []}) {
  return (
    <div className="space-y-1.5">
      <Placeholder>Actions on this process will go here.</Placeholder>
      <div className="flex flex-wrap items-center gap-1 text-[10px] text-base-content/40">
        {actions.map(action => (
          <span key={action} className="rounded-md border border-dashed border-base-content/30 px-1.5 py-0.5">
            {action}
          </span>
        ))}
      </div>
    </div>
  )
}

export function ConfigPanel({label, value}) {
  return (
    <div className="space-y-1.5">
      <Placeholder>Configuration for this process will go here.</Placeholder>
      {label && (
        <p className="text-[10px] text-base-content/40">
          {label} <span className="font-mono">{value}</span>
        </p>
      )}
    </div>
  )
}

// The Add panel from round three: a two-column grid of buttons, one per kind
// of child this process can have, each with a label and a one-line hint.
//
//   options  [{kind, label, hint}]
//   onAdd    called with the option's kind
export function AddPanel({options = [], onAdd}) {
  return (
    <div className="grid grid-cols-2 gap-1.5">
      {options.map(option => (
        <button
          key={option.kind}
          type="button"
          onClick={() => onAdd?.(option.kind)}
          className="rounded-md border border-base-300 bg-base-100 px-2 py-1.5 text-left transition-colors hover:border-base-content/40 active:scale-[0.98]"
        >
          <span className="text-[11px] font-medium">{option.label}</span>
          <span className="block text-[10px] leading-snug text-base-content/60">{option.hint}</span>
        </button>
      ))}
    </div>
  )
}

export function LogsPanel() {
  return (
    <div className="space-y-1">
      <Placeholder>This process's start and exit events will go here, newest first.</Placeholder>
      <p className="text-[10px] text-base-content/40">No events yet.</p>
    </div>
  )
}
