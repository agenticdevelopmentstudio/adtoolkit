
| State | Appearance change |
|-------|------------------|
| Default | On construction, the appearance defaults to a white caret color and white text color, with the always-hollow and marks-active-pane flags both `false`, which resolves to the Filled state below. |
| Pressed | Not applicable: this view renders a text caret, not a pressable control, and defines no pressed-state handling of its own. |
| Disabled | Not applicable: the source never reads or sets an enabled/disabled flag on this view. |
| Focused | Not applicable as a first-responder concept: the caret's hollow/filled decision is driven by the always-hollow/marks-active-pane flags plus the active-pane tracker, not by this view's own key/first-responder status directly. |
| Loading | Not applicable: this view performs no asynchronous work of its own. |
| Filled (custom) | The caret color equals the appearance's own color, the text color is unset, caret subview layer border width `0`. Reached when the always-hollow flag is `false` and either the marks-active-pane flag is `false` or this view is within the active pane. |
| Hollow — always (custom) | The caret color is fully transparent, the text color equals the appearance's own text color, caret subview layer border width `1` in the appearance's own color. Reached whenever the always-hollow flag is `true`. |
| Hollow — inactive pane (custom) | Same appearance as "Hollow — always". Reached when the always-hollow flag is `false`, the marks-active-pane flag is `true`, and this view is not within the active pane. |

