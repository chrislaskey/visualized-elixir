// What each tab opens. Placeholders for now: the shape of each panel from the
// exploration is sketched with text so the drawer has something to show, and
// nothing here is wired to the server yet.

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

export function AddPanel() {
  return <Placeholder>Adding children to this supervisor will go here.</Placeholder>
}

export function LogsPanel() {
  return (
    <div className="space-y-1">
      <Placeholder>This process's start and exit events will go here, newest first.</Placeholder>
      <p className="text-[10px] text-base-content/40">No events yet.</p>
    </div>
  )
}
