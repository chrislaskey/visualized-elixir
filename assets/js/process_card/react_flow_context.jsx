// What the ReactFlow hook makes available to the nodes rendered inside it.
// The nodes are presentational and never touch the nodes/edges state
// directly; they ask the hook to do things through this context.
//
// Two of these edit the graph, which the hook then syncs to the server as
// the "data" event. The third acts on the live process, as an "action"
// event.
//
//   addChild(parentId, kind)     append a child of `kind` under the node with
//                                id `parentId`, kind being a key of
//                                supervisionNodeTypes ("supervisor", ...)
//   updateConfig(nodeId, patch)  merge `patch` into the node's data.config,
//                                e.g. {strategy: "one_for_all"}; the server
//                                restarts the process with the new options
//   act(nodeId, type)            push an "action" event with `type` ("kill",
//                                "stop", ...) and the node id
import {createContext, useContext} from "react"

const noop = () => {}

export const ReactFlowContext = createContext({addChild: noop, updateConfig: noop, act: noop})

export function useReactFlowContext() {
  return useContext(ReactFlowContext)
}
