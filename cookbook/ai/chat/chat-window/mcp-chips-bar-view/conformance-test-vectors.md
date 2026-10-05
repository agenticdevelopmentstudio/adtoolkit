
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcp-chips-bar-001 | applies-theme-consistently | Initialize the bar with a registry and an active-server binding, then open the popover | The bar's content and the popover's content both reflect the app's active theme values (see Platform Notes for the mechanism) |
| mcp-chips-bar-003 | fills-parent-bounds | Initialize with the containing element at bounds `(0, 0, 300, 40)`, then resize the container to `(0, 0, 500, 60)` and let layout settle | The bar's bounds equal `(0, 0, 500, 60)`, matching the container's new bounds on all four edges |
| mcp-chips-bar-005 | shares-one-view-model-between-bar-and-picker | Initialize the view once, open the popover, then switch id1's row toggle | The bar's button label recomputes to reflect the new active count without re-initializing the view — the bar and the popover are driven by the same active-server state |
| mcp-chips-bar-006 | snapshots-active-ids-at-init | Construct with a binding whose value is `{A, B}`, then mutate the binding's external storage to `{C}` before any toggle | The view model's `activeServerIds` remains `{A, B}` |
| mcp-chips-bar-007 | subscribes-to-registry-clients, sorts-available-servers-by-name, rebuilds-server-names-on-update | Registry emits clients `[id1: "Bravo", id2: "alpha"]` | `availableServerIds == [id2, id1]` (case-insensitive "alpha" before "Bravo") and `serverNames == [id1: "Bravo", id2: "alpha"]` |
| mcp-chips-bar-008 | defaults-missing-name-to-empty-string-for-sort | Code inspection of the sort comparator in the view model's initializer (`clients[lhs]?.name ?? ""` / `clients[rhs]?.name ?? ""`) | The comparator falls back to `""` for a missing name instead of crashing or force-unwrapping; this branch is unreachable through the current call site, since the available ids are always sorted against that same clients dictionary, but the defensive default is present and correct if that ever changes |
| mcp-chips-bar-009 | reports-active-membership | `activeServerIds` contains id1 but not id2 | `isActive(id1) == true`, `isActive(id2) == false` |
| mcp-chips-bar-010 | toggles-membership-on-call, propagates-toggle-to-binding | `activeServerIds` does not contain id1; call `toggle(id1)` | `activeServerIds` now contains id1, and the caller's binding's value equals the new set |
| mcp-chips-bar-011 | toggles-membership-on-call, propagates-toggle-to-binding | `activeServerIds` contains id1; call `toggle(id1)` | `activeServerIds` no longer contains id1, and the caller's binding's value equals the new set |
| mcp-chips-bar-012 | renders-server-rack-icon | Render the bar | A server-rack icon is present, foreground-styled with `theme.secondaryText` |
| mcp-chips-bar-013 | computes-no-servers-label | `availableServerIds == []` | Button text reads exactly "No MCP servers" |
| mcp-chips-bar-014 | computes-none-active-label | `availableServerIds == [id1, id2]`, `activeServerIds == []` | Button text reads exactly "MCP: none" |
| mcp-chips-bar-015 | computes-count-active-label | `availableServerIds == [id1, id2, id3]`, `activeServerIds == {id1, id3}` | Button text reads exactly "MCP: 2 of 3" |
| mcp-chips-bar-016 | uses-borderless-button-style | Inspect the toggle button's style | A borderless button style is applied |
| mcp-chips-bar-017 | toggles-picker-on-tap | `showingPicker == false`; tap the button | `showingPicker == true` |
| mcp-chips-bar-018 | presents-popover-below-button | `showingPicker == true` | A popover is presented, anchored below the button |
| mcp-chips-bar-019 | reapplies-theme-inside-popover | Inspect the popover's content | The app's active theme is applied to the server picker's content independently of the bar's own application |
| mcp-chips-bar-020 | applies-bar-padding, trails-with-spacer | Inspect the bar's root layout container | 8pt spacing between children, 12pt horizontal / 6pt vertical padding on the container, and a flexible spacer as the final child |
| mcp-chips-bar-021 | shows-picker-heading | Render the server picker | "Active MCP Servers" is displayed in `theme.font(.heading)` |
| mcp-chips-bar-022 | shows-empty-state-message, lists-one-toggle-row-per-server | `availableServerIds == []` | The empty-state message "No connected servers.\nAdd one in Settings → MCP Servers." is shown and no toggle row is rendered |
| mcp-chips-bar-023 | lists-one-toggle-row-per-server, row-label-falls-back-to-unknown | `availableServerIds == [id1, id2]`, `serverNames == [id1: "Alpha"]` (id2 missing) | Exactly two rows render, in order id1 then id2, labeled "Alpha" and "Unknown" respectively |
| mcp-chips-bar-024 | row-toggle-reflects-active-state | id1 is a member of `activeServerIds` | id1's row toggle reads on (checked) |
| mcp-chips-bar-025 | row-toggle-calls-view-model-toggle | id1's row toggle is switched by the user | `viewModel.toggle(id1)` is invoked exactly once |
| mcp-chips-bar-026 | uses-checkbox-toggle-style | Inspect any rendered row toggle | A checkbox toggle style is applied |
| mcp-chips-bar-027 | applies-picker-padding-and-min-width | Inspect the server picker's root layout container | 8pt spacing, 14pt padding on all sides, and a minimum width of 220pt |
| mcp-chips-bar-028 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

