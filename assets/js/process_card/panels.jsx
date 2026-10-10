// What each tab opens. The Add and Config panels are built; Action and Logs
// are placeholders sketching the shape of each panel from the exploration so
// the drawer has something to show.

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

// The segmented control from round three: one button per option, the chosen
// one dark. Full width, equal columns, so three snake_case atoms fit the
// drawer without wrapping.
//
//   options   [{value}]
//   value     the chosen option's value
//   onChange  called with the clicked option's value
export function Segmented({options, value, onChange, name}) {
  return (
    <div
      className="grid auto-cols-fr grid-flow-col rounded-md border border-base-300 bg-base-100 p-0.5"
      role="radiogroup"
      aria-label={name}
    >
      {options.map(option => {
        const selected = option.value === value
        return (
          <button
            key={option.value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => !selected && onChange?.(option.value)}
            className={[
              "rounded px-1 py-0.5 font-mono text-[10px] transition-colors",
              selected ? "bg-base-content font-semibold text-base-100" : "text-base-content/60 hover:text-base-content",
            ].join(" ")}
          >
            {option.value}
          </button>
        )
      })}
    </div>
  )
}

// The Config panel: one segmented control per option the process takes, with
// a one-line note explaining what the chosen value means. Choosing a value
// reports it straight away; the server restarts the process with the new
// options and the status dot shows it happening.
//
//   fields    [{key, value, options: [{value, note}]}], key being the
//             data.config key ("strategy", "restart")
//   onChange  called with (key, value)
export function ConfigPanel({fields = [], onChange}) {
  return (
    <div className="space-y-2.5">
      {fields.map(field => {
        const chosen = field.options.find(option => option.value === field.value)
        return (
          <div key={field.key} className="space-y-1">
            <div className="text-[11px] text-base-content/60">{field.key}</div>
            <Segmented
              name={field.key}
              options={field.options}
              value={field.value}
              onChange={value => onChange?.(field.key, value)}
            />
            {chosen?.note && <p className="text-[10px] leading-snug text-base-content/50">{chosen.note}</p>}
          </div>
        )
      })}
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
