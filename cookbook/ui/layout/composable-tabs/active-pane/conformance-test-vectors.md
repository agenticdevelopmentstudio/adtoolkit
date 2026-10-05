
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| CTA-01 | tracks-active-node-per-window | Two windows, each with panes activated independently | Each window's active id is independent of the other's |
| CTA-02 | unclaimed-pane-counts-as-active | A pane's backdrop in a window with no recorded active id | Checking whether a view is in the active pane returns `true` for a view inside that backdrop |
| CTA-03 | membership-decided-by-node-id-match | Two panes in one window, one active | Checking membership returns `true` for a view inside the active pane's backdrop and `false` for a view inside the other |
| CTA-04 | view-outside-any-pane-counts-as-active | A view with no pane backdrop ancestor (e.g. a standalone panel) | Checking whether it is in the active pane returns `true` |
| CTA-05 | nil-window-has-no-active-node | Look up the active node id for no window | Returns none |
| CTA-06 | arrival-claims-active-in-an-unclaimed-window | The first pane arrives in a fresh window | That pane becomes the active one |
| CTA-07 | arrival-does-not-steal-active-from-a-live-pane | A window already has an active pane; a second pane arrives | The active id is unchanged |
| CTA-08 | arrival-enables-mouse-moved-tracking-when-setting-on | Pointer-follows setting enabled; a second (non-claiming) pane appears | Pointer-move tracking is enabled on the window |
| CTA-09 | departure-hands-off-to-a-surviving-pane | The active pane departs while a sibling pane remains in the window | The sibling becomes the new active pane |
| CTA-10 | departure-clears-active-id-when-no-pane-survives | The active pane departs and it was the window's only pane | The active node id lookup returns none afterward |
| CTA-11 | departure-of-a-non-active-pane-is-inert | A non-active pane departs | Active id is unchanged; no change notification is posted |
| CTA-12 | window-close-clears-active-id-silently | The window closes | The active node id lookup returns none for that window afterward; no change notification is observed |
| CTA-13 | activation-is-idempotent | Activate a node id already active | No state change; no notification posted |
| CTA-14 | activation-posts-notification-on-change | Activate a different node id | A change notification is posted with that window as its subject |
| CTA-15 | setting-enabled-reaches-already-open-windows | Two windows already tracked, then the pointer-follows setting is turned on | Both windows have pointer-move tracking enabled |
| CTA-16 | accepts-mouse-moved-is-never-reset-to-false | Pointer-follows setting turned on then off again | Pointer-move tracking remains enabled on the window |
| CTA-17 | clicks-are-evaluated-regardless-of-the-setting | Pointer-follows setting disabled; a primary click lands on a different pane | That pane is activated |
| CTA-18 | mouse-moved-is-gated-by-the-setting | Pointer-follows setting disabled; pointer moves to a different pane | Active pane is unchanged |
| CTA-19 | mouse-moved-is-gated-by-key-window | Pointer-follows setting enabled; pointer moves over a non-focused window's pane | Active pane is unchanged |
| CTA-20 | mouse-moved-is-gated-by-an-attached-sheet | Window has an attached sheet; pointer moves over one of its panes | Active pane is unchanged |
| CTA-21 | mouse-moved-is-gated-by-arrange-mode | Arrange mode enabled in the window; pointer moves over a different pane | Active pane is unchanged |
| CTA-22 | event-outside-any-pane-is-ignored | A click lands outside every pane's backdrop | No state change |
| CTA-23 | event-on-the-already-active-pane-is-a-no-op | A click or pointer move lands on the already-active pane | No state change; no notification posted |
| CTA-24 | click-activates-a-different-pane-directly | A primary click lands on a non-active pane | That pane becomes active |
| CTA-25 | mouse-moved-takes-focus-before-activating | Pointer-follows setting enabled; pointer moves onto a non-active pane containing a focusable view | Focus moves to the innermost focusable view before the pane is activated |
| CTA-26 | focus-refusal-blocks-mouse-moved-activation | Outgoing focus holder refuses to give up focus; pointer moves onto a non-active pane | Active pane is unchanged; input focus is unchanged |
| CTA-27 | the-event-monitor-never-consumes-an-event | A primary click lands on a view with its own pointer-down handling, while the local monitor's handler runs first | The hit-tested view's own pointer-down handling is still invoked after the monitor's handler returns the event unmodified |
| CTA-28 | focus-walk-proceeds-innermost-to-outermost | A pane whose innermost hit-tested view refuses focus but an outer one accepts | The outer, focus-accepting view takes input focus |
| CTA-29 | focus-walk-treats-the-current-responder-as-already-taken | The innermost hit-tested view already holds input focus | Taking focus reports success without reassigning focus again |
| CTA-30 | focus-walk-stops-on-outgoing-refusal | The current focus holder refuses to give up focus | Taking focus reports refusal; the walk does not continue to further candidates |
| CTA-31 | focus-walk-restores-the-original-responder-on-exhaustion | Every view in the hit-tested chain reports that it can accept focus but declines to actually take it, so each focus-assignment attempt gives up the outgoing holder yet leaves the window itself holding focus before the walk tries the next candidate | After the walk exhausts every candidate, taking focus reassigns the original focus holder and it succeeds, restoring it; taking focus reports that there was nowhere to put the keys |
| CTA-32 | focus-walk-reports-refused-when-restoration-fails | No candidate accepts focus and restoring the original focus holder fails | Taking focus reports refusal |
| CTA-33 | every-pane-is-always-outlined | Any pane, active or not | The border width is `2` |
| CTA-34 | the-backdrop-is-always-the-pane-backdrop-color | Any pane, active or not | The background equals the theme's pane-backdrop color |
| CTA-35 | the-active-pane-uses-the-accent-outline-color | Pane is active, its window is focused, highlighting enabled | The border color equals the theme's active-pane-outline color |
| CTA-36 | every-other-pane-uses-the-hairline-outline-color | Pane is inactive (or active but window unfocused, or highlighting disabled) | The border color equals the theme's pane-outline color |
| CTA-37 | the-accent-color-requires-a-focused-window | Pane is active but its window is not focused and has no focused attached sheet | The border color equals the theme's pane-outline color, not the accent |
| CTA-38 | an-attached-sheet-counts-the-window-as-focused | Window is not focused but its attached sheet is focused; pane is active | The border color equals the theme's active-pane-outline color |
| CTA-39 | a-theme-override-takes-precedence-over-the-user-setting | Theme's highlight override set to `false`, the user's highlight setting set to `true` | The pane is drawn as not highlighted |
| CTA-40 | the-fill-is-inset-from-the-backdrop-edges | Backdrop laid out at a known frame | The fill subview's frame equals the backdrop's bounds inset by 2pt on every edge |
| CTA-41 | the-fill-is-the-first-subview | Backdrop after construction | The fill is the first subview |
| CTA-42 | a-window-change-reports-departure-before-arrival | A backdrop is moved from window A to window B | Window A's departure handling completes before window B's arrival handling begins |
| CTA-43 | the-backdrop-repaints-on-its-own-windows-activation-change | A tracker change notification posted for the backdrop's own window | Applying the theme is invoked; posting it for a different window does not invoke it |
| CTA-44 | the-backdrop-repaints-on-any-key-window-change | Any window becomes or loses focus | Applying the theme is invoked on every tracked backdrop, including ones in other windows |
| CTA-45 | the-backdrop-repaints-on-a-highlight-setting-change | The highlight setting changes | Applying the theme is invoked |
| CTA-46 | a-hidden-pane-remains-live | A pane's backdrop is hidden by a collapsed split but stays in the window; its window's active pane then departs | The hidden pane is offered as the successor in **departure-hands-off-to-a-surviving-pane** |
| CTA-47 | is-in-active-pane-ignores-key-window | A view inside the active pane's backdrop, queried while its window is not the focused window | Checking membership still returns `true`, the same as when the window is focused |
| CTA-48 | an-event-with-no-window-is-ignored | A monitored event whose window is unset | No state change; recording the event takes no action |
| CTA-49 | a-nil-content-view-means-no-pane | A window whose content view is unset receives a monitored event | Resolving the pane chain returns none; the event is ignored |
| CTA-50 | event-monitor-is-local-to-the-apps-own-windows | A pointer event delivered to a window belonging to a different application | The monitor never observes it; no pane in this app is affected |
| CTA-51 | close-and-highlight-changes-dispatch-through-the-main-queue | The window closes, or the highlight setting changes, while the platform is tracking a pointer-down gesture | The active-id removal or backdrop repaint still applies before the tracking gesture ends, because the handler is queued on the main work queue rather than a mechanism that pauses during the gesture |
| CTA-52 | the-active-pane-uses-the-accent-outline-color | No pane in a window has claimed the active id; applying the theme runs for any pane in it | The border color equals the theme's pane-outline color for every pane in the window, not the accent, even though checking membership reports `true` for a view in any of them |
| CTA-53 | contrast | Theme whose active-pane outline color is close to its pane backdrop color | The active pane's border is drawn in the theme's active-pane-outline color; no contrast adjustment is applied. |
| CTA-54 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

