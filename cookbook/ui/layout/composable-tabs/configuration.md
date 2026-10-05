
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nodeID` | identifier | — (required) | Identity of this node in the persisted layout-node tree; immutable after construction. |
| `axis` | axis (horizontal or vertical) | — (required) | The direction children are arranged along; may change via a rebuild when the persisted shape re-lays the root along the other axis. |
| `workingDirectory` | path | — (required) | The directory every pane in this split, and every split nested inside it, works in; set once at construction. |
| `isRoot` | boolean | — (required) | Whether this instance is the tab's own root; gates persistence, state restoration on first appearance, and reassigning pane identifiers at load. |
| `thicknessFraction` | number or unset | unset | This node's share (`0` to `1`) of the split it sits in; unset means "never sized." |
| `arranger` | arranger | inherited-slot arranger | Governs how thickness fractions are redistributed when panes come and go; a proportional arranger is the built-in alternative. |
| `layoutOverride` | layout override or none | none | A layout this subtree uses instead of the project's own, stamped down the whole subtree. |
| `stateOwnerNodeID` | identifier or none | none | The layout node every pane in this subtree should remember its per-pane state against, for panes that are not layout nodes themselves. |
| `clampsToContainer` | boolean | `false` | Whether this tree's width is the enclosing container's to decide rather than its own; stamped down the whole subtree. |
| `onLayoutDidChange` | callback or none | none | Root-only callback fired with a fresh snapshot whenever a persistable layout change occurs. |
| `onLastPaneCloseRequest` | callback or none | none | Root-only callback that, when set, lets the tab's one required pane be emptied instead of refusing its close button. |
| `zoomedLeaf` | pane or none | none | Root-only: the pane currently taking over the whole tab, if any. |

