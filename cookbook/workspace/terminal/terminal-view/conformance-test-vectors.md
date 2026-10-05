
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| themed-terminal-view-003 | caret-appearance-property | Construct the view and read the appearance property before setting it. | the appearance's color and text color are both white; its always-hollow and marks-active-pane flags are both `false`. |
| themed-terminal-view-004 | appearance-change-recompute | View with the default appearance; set the always-hollow flag to `true`. | the caret color becomes fully transparent and the caret subview's layer border width becomes `1`, without any other call. |
| themed-terminal-view-005 | window-attach-recompute | View constructed with the always-hollow flag `true`, not yet attached to a window; attach it to a window. | once attached, the caret color is fully transparent and the caret subview's border width is `1`. |
| themed-terminal-view-006 | active-pane-subscription | Construct the view, attach it to a window, then immediately post the active-pane tracker's change notification naming that window, with no other intervening call. | the caret's color/border are recomputed in response, showing the subscription was already active right after construction. |
| themed-terminal-view-007 | active-pane-notification-window-filter | View is in window A; post the active-pane tracker's change notification naming window B. | the view's caret color/border are unchanged. |
| themed-terminal-view-008 | active-pane-notification-window-filter | View is in window A; post the active-pane tracker's change notification naming window A. | the caret is recomputed and its color/border reflect the current appearance/active-pane state. |
| themed-terminal-view-009 | cursor-shown-outline-reapply | The appearance's marks-active-pane flag is `true` and always-hollow is `false`; the view is currently the active pane (filled: border width `0`). Without changing the appearance, another pane in the same window becomes active (so the view would now be outside the active pane), but no change notification reaches this view's window; then signal that the cursor is shown. | the caret subview's border width stays `0` and the caret color stays the appearance's own color — the stale computed state from before the pane change, not a freshly recomputed one. |
| themed-terminal-view-010 | cursor-style-change-outline-reapply | The appearance's marks-active-pane flag is `true` and always-hollow is `false`; the view is currently NOT the active pane (hollow: border width `1`). Without changing the appearance, this view's pane becomes active (so the view would now be within the active pane), but no change notification reaches this view; then signal a cursor-style change, with any style. | the caret subview's border width stays `1` in the appearance's own color regardless of the new style — the stale hollow state persists. |
| themed-terminal-view-011 | always-hollow-flag | The always-hollow flag is `true`, the marks-active-pane flag is `true`, the view is in the active pane. | the caret is hollow. |
| themed-terminal-view-012 | active-pane-marking | The always-hollow flag is `false`, the marks-active-pane flag is `true`, and the view is not within the active pane. | the caret is hollow. |
| themed-terminal-view-013 | active-pane-marking | The always-hollow flag is `false`, the marks-active-pane flag is `true`, and the view is within the active pane. | the caret is filled. |
| themed-terminal-view-014 | default-fill | The always-hollow flag is `false`, the marks-active-pane flag is `false`, the view is not inside any composable-tabs pane. | the caret is filled. |
| themed-terminal-view-015 | hollow-caret-color | The caret is computed as hollow. | the caret color is fully transparent. |
| themed-terminal-view-016 | filled-caret-color | The caret is computed as filled, with the appearance's color set to a particular blue. | the caret color equals that blue. |
| themed-terminal-view-017 | hollow-text-color | The caret is computed as hollow, with the appearance's text color set to black. | the caret text color equals black. |
| themed-terminal-view-018 | filled-text-color | The caret is computed as filled. | the caret text color is unset. |
| themed-terminal-view-019 | hollow-border | The caret is computed as hollow, the caret subview is present, the appearance's color is a particular blue. | the caret subview's layer border width is `1`, and its border color equals that blue. |
| themed-terminal-view-020 | filled-border | The caret is computed as filled, the caret subview is present. | the caret subview's layer border width is `0`, and it has no border color. |
| themed-terminal-view-021 | missing-caret-subview-tolerance | No subview whose type name ends in `"CaretView"` exists (for example, the border is applied before the terminal engine adds its caret). | no exception is thrown; no layer property is modified. |
| themed-terminal-view-022 | caret-subview-type-name-match | Add a subview whose dynamic type name is `"XTermCaretView"`. | the caret-subview lookup resolves to that subview. |
| themed-terminal-view-023 | caret-subview-cache | The caret subview is resolved once; the resolved subview is removed and replaced by a new subview of a matching type name. | a subsequent lookup re-searches and returns the new subview rather than the stale (now-detached) one. |
| themed-terminal-view-024 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

`confines-to-ui-thread` has no row here: it is a compile-time
guarantee, verified by the language's own isolation checking, not by a
runtime conformance vector (see Design Decisions).

