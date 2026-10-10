// What each tab opens. Action, Config, and Add are built; Logs is a
// placeholder sketching the shape of the panel from the exploration so the
// drawer has something to show.

function Placeholder({children}) {
  return <p className="text-[11px] leading-snug text-base-content/60">{children}</p>
}

// A two-column grid of buttons, each a label with a one-line hint. The Add
// and Action panels are both this: a handful of things the process can do,
// each explained in place so the card teaches as it goes. No colours; the
// hint carries the weight.
//
//   choices   [{id, label, hint}]
//   onChoose  called with the clicked choice's id
export function ChoiceGrid({choices = [], onChoose}) {
  return (
    <div className="grid grid-cols-2 gap-1.5">
      {choices.map(choice => (
        <button
          key={choice.id}
          type="button"
          onClick={() => onChoose?.(choice.id)}
          className="min-w-0 rounded-md border border-base-300 bg-base-100 px-2 py-1.5 text-left transition-colors hover:border-base-content/40 active:scale-[0.98]"
        >
          <span className="text-[11px] font-medium">{choice.label}</span>
          <span className="block break-words text-[10px] leading-snug text-base-content/60">{choice.hint}</span>
        </button>
      ))}
    </div>
  )
}

// The Action panel: what can be done to the running process. The panel
// stays open after a click so an action can be repeated, say killing a
// process a few times to watch its supervisor give up.
//
//   actions  [{id, label, hint}]
//   onAct    called with the action's id
export function ActionPanel({actions = [], onAct}) {
  return <ChoiceGrid choices={actions} onChoose={onAct} />
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

// The Add panel: one button per kind of child this process can have.
//
//   options  [{kind, label, hint}]
//   onAdd    called with the option's kind
export function AddPanel({options = [], onAdd}) {
  const choices = options.map(option => ({id: option.kind, label: option.label, hint: option.hint}))
  return <ChoiceGrid choices={choices} onChoose={onAdd} />
}

export function LogsPanel() {
  return (
    <div className="space-y-1">
      <Placeholder>This process's start and exit events will go here, newest first.</Placeholder>
      <p className="text-[10px] text-base-content/40">No events yet.</p>
    </div>
  )
}
