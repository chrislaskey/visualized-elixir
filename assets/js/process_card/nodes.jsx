// Custom ReactFlow nodes for the supervision tree, each a ProcessCard with
// the handles that edges attach to. Edges mean "supervises", so only a
// supervisor has a source handle on its bottom edge.
//
// Each node renders what the server told it:
//
//   data.label      "Supervisor 2"
//   data.order      "#2/3", optional
//   data.subtitle   config summary for the header, optional
//   data.config     {strategy} for supervisors, {restart} for GenServers
//   data.status     {state, restarts, last_exit}, layered on at render time
//                   by the canvas (see the hook); absent means not supervised
//   data.root       true for the application's root supervisor
import {Handle, Position} from "@xyflow/react"
import {KIND_ICONS, ProcessCard, TABS} from "./process_card.jsx"
import {ActionPanel, AddPanel, ConfigPanel, LogsPanel} from "./panels.jsx"
import {useReactFlowContext} from "./react_flow_context.jsx"

// What a supervisor can add. One kind for now; a GenServer option joins it
// once there is a GenServer to start.
const SUPERVISOR_ADDS = [
  {kind: "supervisor", label: "+ Supervisor", hint: "A child supervisor with its own strategy"},
]

const HANDLE_CLASS = "!size-3 !rounded-full !border-2 !border-base-100 !bg-base-content/40"

function statusProps(data) {
  const status = data.status
  return {
    state: status?.state ?? "none",
    restarts: status?.restarts ?? 0,
    lastExit: status?.last_exit ?? null,
  }
}

function tabsFor(ids) {
  return TABS.filter(tab => ids.includes(tab.id))
}

export function SupervisorNode({id, data}) {
  const {addChild} = useReactFlowContext()
  const strategy = data.config?.strategy
  const subtitle = data.subtitle ?? (strategy ? `${strategy} · gives up after 3 in 5s` : undefined)

  const panels = {
    action: <ActionPanel actions={["Kill", "Stop", "Delete"]} />,
    config: <ConfigPanel label="strategy" value={strategy} />,
    add: ({close}) => (
      <AddPanel
        options={SUPERVISOR_ADDS}
        onAdd={kind => {
          addChild(id, kind)
          close()
        }}
      />
    ),
    logs: <LogsPanel />,
  }

  return (
    <ProcessCard
      icon={KIND_ICONS.supervisor}
      label={data.label}
      order={data.order}
      kindName="Supervisor"
      subtitle={subtitle}
      tabs={tabsFor(["action", "config", "add", "logs"])}
      panels={panels}
      {...statusProps(data)}
    >
      {!data.root && <Handle type="target" position={Position.Top} className={HANDLE_CLASS} />}
      <Handle type="source" position={Position.Bottom} className={HANDLE_CLASS} />
    </ProcessCard>
  )
}

export function GenServerNode({data}) {
  const restart = data.config?.restart
  const subtitle = data.subtitle ?? (restart ? `${restart}` : undefined)

  const panels = {
    action: <ActionPanel actions={["Crash", "Kill", "Stop", "Delete"]} />,
    config: <ConfigPanel label="restart" value={restart} />,
    logs: <LogsPanel />,
  }

  return (
    <ProcessCard
      icon={KIND_ICONS.genserver}
      label={data.label}
      order={data.order}
      kindName="GenServer"
      subtitle={subtitle}
      tabs={tabsFor(["action", "config", "logs"])}
      panels={panels}
      {...statusProps(data)}
    >
      <Handle type="target" position={Position.Top} className={HANDLE_CLASS} />
    </ProcessCard>
  )
}

// Keyed by the node `type` the server sends. A GenStage canvas would register
// its own map (producer, consumer, producer_consumer) alongside this one.
export const supervisionNodeTypes = {
  supervisor: SupervisorNode,
  genserver: GenServerNode,
}
