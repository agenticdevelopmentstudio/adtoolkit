
| State | Appearance change |
|-------|------------------|
| Default | — |
| Pressed | Not applicable: this component draws no custom pressed appearance for a row; clicking selects it via the tree's own default selection chrome. |
| Disabled | Not applicable: neither pane nor row has a disabled representation in this component; whether an activated item does anything is entirely the extension's command wiring, not this pane's concern. |
| Focused | Not applicable as a visual state drawn by this component: keyboard focus ring and focus chrome are inherited, undrawn platform default behavior. |
| Loading | Not applicable as a whole-pane state: there is no spinner or full-pane loading indicator anywhere in this component; loading is per-branch — see "Branch unloaded" and "Branch timed out" below. |
| Placeholder | Shown until a data source resolves; drawn by the placeholder component, out of this recipe's scope. |
| Tree shown | The placeholder is replaced by the tree once a data source resolves (`first-resolve-shows-outline`). |
| Message banner visible | Shown, wrapped, above the tree whenever the data source's message is non-empty. |
| Message banner hidden | Hidden, tree pinned to the container's top edge, whenever the data source's message is empty. |
| Branch unloaded | Drawn with zero rows while a load is in flight or has not yet been triggered; its own disclosure triangle still shows if `collapsibleState` is not `.none` (`disclosure-driven-by-declared-state`). |
| Branch timed out | Drawn with zero rows after `childrenBudget` elapses with no answer; stays re-askable rather than being recorded as permanently empty. |
| Row selected | Standard tree selection highlighting, not drawn by this component; reported to the data source's selection-changed callback unless the change was the pane's own redraw sync. |
| Row expanded/collapsed | Standard tree disclosure, not drawn by this component; reported via expand/collapse callbacks unless the change was the pane's own auto-expand or redraw sync. |

