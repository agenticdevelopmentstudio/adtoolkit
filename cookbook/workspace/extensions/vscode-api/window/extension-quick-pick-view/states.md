
| State | Appearance change |
|-------|------------------|
| Default | Title label (if any) shown; search field shows `model.request.placeHolder` (or empty); table lists `model.visibleIndices`; the highlighted row, if any, is selected. |
| Pressed | Single-select: clicking a row highlights it, syncs selection, and immediately calls `onAccept` (accept-on-click). Multi-select: clicking a row or its checkbox toggles that row's check and reloads only that row; the panel stays open. Either mode: a click on a separator or out-of-range row is a no-op. |
| Disabled | Not applicable: no control in this component is ever disabled; every view is always enabled. |
| Focused | The search field holds keyboard focus from the moment focus is requested for it (triggered externally when the hosting window takes its initial focus) — see **search-field-focus**; the table refuses keyboard focus and is never itself focused — the highlighted row is instead shown through table selection plus the table row's own rounded selection fill (the selection color role, 4pt corner radius, inset 2pt/1pt), not a native focus ring. |
| Loading | Not applicable: no asynchronous operation, spinner, or loading flag appears anywhere in this component; the model is built synchronously from the request at construction. |

