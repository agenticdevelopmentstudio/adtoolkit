
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| composable-tabs-arrange-overlay-001 | dims-content-with-scrim | Inspect the layer's background color immediately after construction | Equals the theme's window-background role at 72% opacity for the active theme |
| composable-tabs-arrange-overlay-002 | paints-toolbar-surface | Inspect the toolbar's layer after construction | Corner radius is 8, border width is 1, background equals the elevated-surface role, border color equals the border role |
| composable-tabs-arrange-overlay-003 | applies-theme-immediately-and-on-change | Construct the view under theme A, then switch the active theme to B | Colors match theme A's palette immediately after construction, and update to match theme B's palette after the switch, with no further action taken |
| composable-tabs-arrange-overlay-004 | centers-toolbar-column | Inspect the column's constraints after construction | The column is centered horizontally and vertically on the view's own center; the label-to-toolbar spacing in the column is 10pt |
| composable-tabs-arrange-overlay-005 | caps-name-label-width | Inspect the pane-name label's width constraint after construction | A constraint capping its width at the view's own width minus 16pt exists |
| composable-tabs-arrange-overlay-006 | truncates-name-label-tail | Set the pane name to a string wider than the label's constrained width | The label truncates at the tail and is center-aligned |
| composable-tabs-arrange-overlay-007 | toolbar-can-overhang-narrow-pane | Inspect the column's constraints against the view for leading/trailing/top/bottom pins | No such constraint exists; only centering constraints tie the column to the view |
| composable-tabs-arrange-overlay-008 | updates-pane-name-on-assignment | Set the pane name to "Editor" | The label's displayed text equals "Editor" immediately after the assignment returns |
| composable-tabs-arrange-overlay-009 | exposes-add-button-as-anchor-view | Read the exposed Add-button anchor | Returns the same view instance used as the Add button |
| composable-tabs-arrange-overlay-010 | invokes-add-callback-on-tap | Set the Add callback to a closure that increments a counter, then click the Add button | Counter increments by exactly 1 |
| composable-tabs-arrange-overlay-011 | invokes-add-callback-on-tap | Leave the Add callback unset, then click the (enabled) Add button | No crash and no observable effect occurs |
| composable-tabs-arrange-overlay-012 | invokes-remove-callback-on-tap | Set the Remove callback to a closure that increments a counter, then click the Remove button | Counter increments by exactly 1 |
| composable-tabs-arrange-overlay-013 | invokes-remove-callback-on-tap | Leave the Remove callback unset, then click the (enabled) Remove button | No crash and no observable effect occurs |
| composable-tabs-arrange-overlay-014 | invokes-done-callback-on-tap | Set the Done callback to a closure that increments a counter, then click the Done button | Counter increments by exactly 1 |
| composable-tabs-arrange-overlay-015 | invokes-done-callback-on-tap | Leave the Done callback unset, then click the Done button | No crash and no observable effect occurs |
| composable-tabs-arrange-overlay-016 | invokes-move-callback-on-selection | Set the Move callback to a closure capturing its argument; available directions is `{left}`; choose the "Left" Move item | Closure is invoked exactly once with "left" |
| composable-tabs-arrange-overlay-017 | invokes-move-callback-on-selection | Leave the Move callback unset; choose an enabled Move item | No crash and no observable effect occurs |
| composable-tabs-arrange-overlay-018 | add-button-enablement-tracks-can-add | Set the can-add callback to return `false`, then refresh availability | The Add button is disabled |
| composable-tabs-arrange-overlay-019 | remove-button-enablement-tracks-can-remove | Set the can-remove callback to return `false`, then refresh availability | The Remove button is disabled |
| composable-tabs-arrange-overlay-020 | move-menu-rebuilt-on-refresh | Refresh availability twice in a row | The Move menu's first item is still its original title item, followed by exactly 4 items, in both cases, in Left/Right/Up/Down order |
| composable-tabs-arrange-overlay-021 | move-item-enablement-tracks-available-directions | Set available directions to `{left, above}`, then refresh availability | The "Left" and "Up" items are enabled; "Right" and "Down" are disabled |
| composable-tabs-arrange-overlay-022 | move-button-enablement-tracks-items | Set available directions to the empty set, then refresh availability | The Move button is disabled |
| composable-tabs-arrange-overlay-023 | move-button-enablement-tracks-items | Set available directions to `{right}`, then refresh availability | The Move button is enabled |
| composable-tabs-arrange-overlay-024 | move-items-icons-match-direction | Inspect the "Up" Move item after refreshing availability | Its image is the `arrow.up` icon and its accessibility description equals "Up" |
| composable-tabs-arrange-overlay-025 | toolbar-buttons-show-icon-and-label | Inspect the Remove button after construction | Its image is the `minus` icon, accessibility description equals "Remove", and the icon is positioned leading of the text |
| composable-tabs-arrange-overlay-026 | refresh-is-caller-driven | Change what the can-add callback returns without refreshing availability | The Add button's enabled state remains at its previously computed value |
| composable-tabs-arrange-overlay-027 | computes-initial-availability-at-construction | Construct the view with the can-add callback returning `false` and never refresh availability again | The Add button is disabled immediately after construction |
| composable-tabs-arrange-overlay-028 | root-and-controls-carry-accessibility-identifiers | Inspect the accessibility identifier on the root view and each control after construction | Equal `composable-tabs.arrange.scrim`, `.add`, `.remove`, `.move`, `.done`, and `.pane-name` respectively |
| composable-tabs-arrange-overlay-029 | move-items-carry-prefixed-identifiers | Refresh availability after construction | The "Left" item's identifier is `composable-tabs.arrange.move.left` |
| composable-tabs-arrange-overlay-030 | done-button-has-no-key-equivalent | Inspect the Done button's key equivalent after construction | Equals none (empty) |
| composable-tabs-arrange-overlay-031 | scrim-blocks-clicks-to-content | With the overlay installed over a pane's content, click a point over the scrim but off any button | The content underneath receives no pointer or key event for that click |
| composable-tabs-arrange-overlay-032 | scrim-click-still-reaches-pane-selection | With the overlay installed over an unselected pane, click a point over the scrim but off any button | The pane becomes the selected pane, via the click reaching the pane's background view's selection handling through the event-handling chain |
| composable-tabs-arrange-overlay-033 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

