
| State | Appearance change |
|-------|--------------------|
| Default (initial load) | "Add" choice list lists all offered entries in order; "Where" choice list lists Left/Right/Above/Below and selects "Right"; OK's enabled state is fixed from whether any entry was offered. |
| Choices non-empty | OK button is enabled. |
| Choices empty | OK button is disabled; "Add" choice list has zero items. |
| Selection changed (user) | The chosen item shows as selected; no other view updates in response — OK's enabled state does not react to the change. |
| Pressed | Not applicable — Cancel/OK use the platform's standard button style; source overrides no pressed/highlight rendering. |
| Focused | Not applicable — source sets no custom focus ring or explicit key-view loop; whichever control is focused uses the platform's default focus indicator and the default subview tab order. |
| Disabled | Applies only to OK, per "Choices empty" above; the disabled appearance is the platform's standard dimmed style, not custom-drawn. |
| Loading | Not applicable — the offered entries are supplied synchronously at construction, and the whole view hierarchy is built synchronously when the sheet loads; source defines no asynchronous or pending state. |

