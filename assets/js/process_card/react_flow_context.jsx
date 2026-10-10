// What the ReactFlow hook makes available to the nodes rendered inside it.
// The nodes are presentational and never touch the nodes/edges state
// directly; they ask the hook to do things through this context.
//
//   addChild(parentId, kind)     append a child of `kind` under the node with
//                                id `parentId`, kind being a key of
//                                supervisionNodeTypes ("supervisor", ...)
//   updateConfig(nodeId, patch)  merge `patch` into the node's data.config,
//                                e.g. {strategy: "one_for_all"}. The hook
//                                pushes the new graph to the server, which
//                                restarts the process with the new options.
import {createContext, useContext} from "react"

const noop = () => {}

export const ReactFlowContext = createContext({addChild: noop, updateConfig: noop})

export function useReactFlowContext() {
  return useContext(ReactFlowContext)
}
