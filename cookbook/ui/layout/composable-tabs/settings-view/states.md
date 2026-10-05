
| State | Appearance change |
|-------|------------------|
| Default | Sheet opens with the Tabs panel selected; each edge toggle reflects `isEdgeEnabled(edge)`; Done is enabled. |
| On (edge toggle) | Toggle is on, title drawn in the primary-text color and body text style; set on init when `isEdgeEnabled(edge)` is `true`, and after any toggle that `isEdgeEnabled` confirms as enabled. |
| Off (edge toggle) | Toggle is off; set on init when `isEdgeEnabled(edge)` is `false`, and after any toggle — including a refused attempt to disable the last enabled edge, which this component re-reads back to on rather than leaving it off (see **reverts-checkbox-to-authoritative-state**). |
| Pressed | Not applicable: this component sets no custom pressed-state styling; the toggles', Done button's, and Spacing controls' click/press feedback is the platform's own default control rendering. |
| Disabled | Not implemented in the component: enablement is never read or set on any control here — the Done button, the four toggles, and both spacing controls are always interactive whenever the sheet is on screen. |
| Focused | Not styled beyond the platform's native focus indication, except for the explicit focus loop this component stitches between the two Spacing controls (**closes-tab-loop-between-spacing-controls**); the Done button and the four toggles use the platform's default focus-order placement, which this component does not override. |
| Loading | Not applicable: no asynchronous operation, spinner, or loading indicator appears anywhere in this component. |

