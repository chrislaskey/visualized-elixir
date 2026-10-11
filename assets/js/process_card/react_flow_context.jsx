// What the ReactFlow hook makes available to the nodes rendered inside it.
// The nodes are presentational and never touch the nodes/edges state
// directly; they ask the hook to do things through this context.
//
// All but one of these edit the graph, which the hook then syncs to the
// server as the "data" event. `act` acts on the live process instead, as an
// "action" event.
//
//   addChild(parentId, kind)     append a child of `kind` under the node with
//                                id `parentId`, kind being a key of
//                                supervisionNodeTypes ("supervisor", ...)
//   updateConfig(nodeId, patch)  merge `patch` into the node's data.config,
//                                e.g. {strategy: "one_for_all"}; the server
//                                restarts the process with the new options
//   act(nodeId, type)            push an "action" event with `type` ("kill",
//                                "stop", ...) and the node id
//   removeNode(nodeId)           delete the node and every edge attached to it
//   removeEdges(nodeId)          delete every edge attached to the node and
//                                leave the node in place
import {createContext, useContext} from "react"

const noop = () => {}

export const ReactFlowContext = createContext({
  addChild: noop,
  updateConfig: noop,
  act: noop,
  removeNode: noop,
  removeEdges: noop,
})

export function useReactFlowContext() {
  return useContext(ReactFlowContext)
}
