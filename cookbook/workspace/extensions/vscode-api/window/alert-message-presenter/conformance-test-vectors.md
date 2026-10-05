
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ns-alert-message-presenter-001 | button-plan-skip-flagged, button-plan-cancel-slot | Plan the button layout for item titles `["A", "B", "C"]` with close-affordance indices `[]` | Returns `[0, 1, 2, nothing]` |
| ns-alert-message-presenter-002 | button-plan-skip-flagged, button-plan-cancel-slot | Same items, close-affordance indices `[0]` | Returns `[1, 2, 0]` |
| ns-alert-message-presenter-003 | button-plan-skip-flagged, button-plan-cancel-slot | Same items, close-affordance indices `[0, 2]` (two items flagged) | Returns `[1, 2]` — the last flagged index, `2`, wins the cancel slot |
| ns-alert-message-presenter-004 | button-plan-skip-flagged, button-plan-cancel-slot | Same items, close-affordance indices `[0, 1, 2]` (every item flagged) | Returns `[2]` — no ordinary button survives the skip |
| ns-alert-message-presenter-005 | button-plan-skip-flagged, button-plan-cancel-slot | Item titles `["A"]`, close-affordance indices `[]` | Returns `[0, nothing]` |
| ns-alert-message-presenter-006 | button-plan-skip-flagged, button-plan-cancel-slot | Item titles `["A"]`, close-affordance indices `[0]` | Returns `[0]` |
| ns-alert-message-presenter-007 | escape-key-position-rule | Compute the Escape-key position for the plans `[0, 1, 2, nothing]`, `[1, 2, 0]`, and `[1, 2]` | Returns `3`, `2`, and `1` respectively — each plan's own last index |
| ns-alert-message-presenter-008 | escape-key-position-rule | Same computation on `[0]` and `[2]` (one-entry plans) | Returns nothing for both |
| ns-alert-message-presenter-009 | empty-items-single-ok | Present a request with empty item titles, presented with a window available | Adds exactly one `OK` button and returns nothing unconditionally, regardless of that button's response |
| ns-alert-message-presenter-010 | severity-style-mapping | Map the severities information, warning, and error to an alert style | Returns informational, warning, and critical respectively |
| ns-alert-message-presenter-011 | drop-when-no-window, dropped-message-logged | Present a request where the injected window-lookup function returns nothing and no window the app currently has satisfies both visibility and eligibility to become the main window | Resolving the presentation window returns nothing; resolving the response logs an error-level message and returns nothing without presenting any alert; presenting the request resolves to nothing |
| ns-alert-message-presenter-012 | response-to-item-index, out-of-range-response-resolves-absent | Present a non-empty-items request where the user's response, once reduced to a button index, falls within the button-plan entries' bounds, versus a (defensive) case where it does not | Returns the corresponding button-plan entry (an item index, or nothing for the cancel slot) in the first case, and nothing in the second without an out-of-bounds access |
| ns-alert-message-presenter-013 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

