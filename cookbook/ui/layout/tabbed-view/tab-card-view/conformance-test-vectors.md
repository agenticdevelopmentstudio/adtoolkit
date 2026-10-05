
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tab-pane-001 | accessibility-ids-assigned-per-instance | Construct the card for a given edge and tab ID | The card's own accessibility identifier is `tab-pane.<id>`; the agent label's is `tab-pane.agent.<id>` (and likewise for the other four fields and the close control) |
| tab-pane-002 | labels-truncate-by-middle-default | Construct the card | The agent, session, and branch labels all truncate overflowing text in the middle |
| tab-pane-003 | labels-resist-compression-at-low-priority | Construct the card | The agent label is the first to shrink under horizontal space pressure, at the lowest resistance priority |
| tab-pane-004 | directory-label-truncates-head | Construct the card | The directory label truncates overflowing text at its head |
| tab-pane-005 | summary-label-truncates-tail | Construct the card | The summary label truncates overflowing text at its tail |
| tab-pane-006 | labels-not-selectable | Construct the card | None of the five text labels are selectable |
| tab-pane-007 | summary-label-hidden-by-default | Construct the card, before any content is set | The summary label starts hidden |
| tab-pane-008 | close-button-configuration | Construct the card | The close control has no border or bezel, shows only its icon, and its hit area is `14×14`pt |
| tab-pane-009 | close-action-forwards-to-onclose | Set a close callback; simulate a press of the close control | The callback fires |
| tab-pane-010 | header-close-button-placement | Construct the card for the left edge vs. any other edge | On the left edge the header places the close control first; on every other edge it places it last |
| tab-pane-011 | header-gap-absorbs-extra-width | Widen the header beyond its content's natural width | The gap between the agent/status group and the close control grows; the agent label and status row do not stretch |
| tab-pane-012 | content-padding | Inspect the content column's edge insets | `top == 12`, `left == 14`, `bottom == 12`, `right == 14` |
| tab-pane-013 | content-stack-order | Inspect the content column's arranged elements | Order is header, session label, directory label, branch label, summary label, spacer |
| tab-pane-014 | header-width-matches-content | Lay out the card | The header's width equals the content column's width minus `26`pt |
| tab-pane-015 | spacer-absorbs-extra-height | Give the card more height than its text needs | The trailing spacer in the content column grows; the five text lines stay at the top |
| tab-pane-016 | self-not-pinned-either-axis | Inspect the card's own constraints | No required-priority constraint pins the card's width or height directly |
| tab-pane-017 | content-size-floors | All labels empty, no status symbols, on the top edge | Content size is `240×136`pt |
| tab-pane-018 | content-size-grows-with-recession-slack | Compare content size on the top edge vs. the left edge, with identical content sized to land clear of both size floors and ceilings on either edge | The left edge's content size is exactly `2 × 12 = 24pt` larger than the top edge's, on both width and height |
| tab-pane-019 | front-card-defined-by-zero-depth | Set depth to `0`, then to `1` | The card reads as front, then as not front (verified indirectly via its reported fill color) |
| tab-pane-020 | depth-change-applies-only-on-change | Record the card's fill color, border color, and running move animations, then set depth to its current value | All three are unchanged afterward: no new animation appears and the colors match the values recorded before the redundant set |
| tab-pane-021 | depth-recession-flat-on-horizontal-edge | Top edge; set depth to `1`, then `5` | Recession is `4pt` in both cases |
| tab-pane-022 | depth-recession-accumulates-on-vertical-edge | Left edge; set depth to `1`, `2`, `3` | Recession is `4pt`, `8pt`, `12pt` respectively |
| tab-pane-023 | depth-recession-clamps-past-max-stack-depth | Left edge; set depth to `3`, then `10` | Recession is `12pt` in both cases |
| tab-pane-024 | front-card-overhangs-workspace | Top edge; set depth to `0` | The card's reported workspace overhang is `1` |
| tab-pane-025 | text-stays-inset-on-workspace-side | Top edge; set depth to `0` | The text column's workspace-facing edge stays at the card's slot boundary, while the painted background's workspace-facing edge extends past it |
| tab-pane-026 | front-card-palette | Set depth to `0` | The reported fill color matches the workspace-backdrop role; the reported border color matches the workspace-outline role |
| tab-pane-027 | behind-card-palette | Set depth to `1` | The reported fill color matches the window-background role; the reported border color matches the border role |
| tab-pane-028 | front-card-agent-label-role | Toggle depth between `0` and `1` | The agent label's role toggles between accent and primary text |
| tab-pane-029 | front-card-session-label-role | Toggle depth between `0` and `1` | The session label's role toggles between primary text and secondary text |
| tab-pane-030 | front-card-secondary-label-roles | Toggle depth between `0` and `1` | The directory, branch, and summary labels' roles each toggle between secondary text and tertiary text |
| tab-pane-031 | close-button-tint-follows-depth | Toggle depth between `0` and `1` | The close control's tint toggles between the secondary-text and tertiary-text role colors |
| tab-pane-032 | theme-change-repaints-card | Change the active theme | The card's reported fill and border colors update to the new theme's values with no other call |
| tab-pane-033 | animated-only-when-in-window | Change depth on a card not attached to a window, then on one attached to a window | No move animation appears in the first case; one appears (mid-transition) in the second |
| tab-pane-034 | depth-animation-duration-and-curve | Change depth on a card attached to a window | The running animation's duration is `0.16` and its timing curve is ease-out |
| tab-pane-035 | depth-animation-settles-pending-layout-first | Resize the card without letting a pending layout settle, then change depth on a card attached to a window | The running animation's starting frame equals the frame the pending layout would have produced, not the frame from before the resize — no stale frame is animated from |
| tab-pane-036 | context-menu-delegates-to-provider | Set a context-menu provider that returns a given menu; request a context menu | Returns that exact menu |
| tab-pane-037 | context-menu-delegates-to-provider | Leave the context-menu provider returning nothing; request a context menu | Returns the platform's default context menu |
| tab-pane-038 | status-symbols-replace-existing | Replace the status symbols with two, then with one | Only one status icon remains after the second call, with no leftover icons from the first |
| tab-pane-039 | status-symbol-view-configuration | Replace the status symbols with one idle symbol | The added icon's frame is `14×14`; it renders at `11`pt; its accessibility label reads "Idle" |
| tab-pane-040 | status-symbol-missing-image-fallback | Replace the status symbols with one whose icon name does not resolve | No crash; the resulting icon is a non-nil empty image |
| tab-pane-041 | zero-size-card-draws-nothing | Force the card's background painting to zero-size bounds; trigger a redraw | No fill or stroke operation is issued (no crash, no drawn path) |
| tab-pane-042 | card-path-omits-workspace-side | Top-edge card; inspect the drawn outline | The path touches only the left, top, and right sides; the bottom (workspace) side has no segment between its two corner points |
| tab-pane-043 | stroke-inset-by-half-point | Top-edge card, not reaching over the workspace | The stroke bounds are inset `0.5pt` from the card's bounds on every side |
| tab-pane-044 | reaches-over-workspace-restores-half-point | Top-edge card, reaching over the workspace | The stroke bounds' workspace-facing edge is extended back out by `0.5pt` relative to the non-overhanging case |
| tab-pane-045 | card-fill-and-border-color-accessors | Set the card's painted fill color to a given color | The card's reported fill color matches it |
| tab-pane-046 | workspace-overhang-accessor | Query the card's reported workspace overhang before layout has run | Returns `0` |
| tab-pane-047 | running-move-animations-accessor | Mid-way through an animated depth change | The card's set of in-progress move animations is non-empty |
| tab-pane-048 | onclose-is-optional | Leave the close callback unset; press the close control | No crash; no observable side effect |
| tab-pane-049 | context-menu-provider-is-optional | Leave the context-menu provider unset; request a context menu | Returns the platform's default context menu |
| tab-pane-050 | status-symbols-replace-existing | On a freshly constructed card with no prior status symbols, replace the status symbols with none | No status icons remain |
| tab-pane-051 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

