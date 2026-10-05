
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ctpvc-001 | nodeid-identity | Read `nodeID` immediately after construction and again after several lifecycle callbacks | Both reads return the same UUID passed at construction |
| ctpvc-002 | pane-number-identity | Read `paneNumber` after construction | Equals the value passed at construction |
| ctpvc-003 | view-id-identity | Read `viewID` after construction | Equals the value passed at construction |
| ctpvc-004 | working-directory-identity | Read `workingDirectory` after construction | Equals the location passed at construction |
| ctpvc-006 | content-from-registry | A pane whose project is alive and `viewID` is registered | The content returned equals what the registry returns when asked for that view id with the same node id, project, working directory, pane number, state-owner node id, and root split node id |
| ctpvc-007 | content-nil-without-project | The project this pane depends on is no longer available before the view loads | No content is returned; the registry is never consulted |
| ctpvc-008 | content-layout-override-precedence | `layoutOverride` is set to a layout whose registry differs from the project's own layout's | Content is built from `layoutOverride`'s registry, not the project's own |
| ctpvc-009 | container-draws-active-outline | Load the pane's view | The pane's view is a container view whose `nodeID` equals the pane's `nodeID` |
| ctpvc-010 | content-inset-matches-border | Load the pane's view | The title bar's top/leading constraints and the content's trailing/bottom constraints all use a constant of 2pt |
| ctpvc-011 | fallback-title-from-registry | Content that does not provide its own title; `viewID` registered with display name "Terminal" | `fallbackTitle` (and therefore the resolved title) is "Terminal" |
| ctpvc-012 | fallback-title-placeholder-layout | `layoutOverride` unset, the project no longer available | `fallbackTitle` returns a name resolved from a placeholder-only layout rather than crashing |
| ctpvc-013 | accessibility-id-from-view-id | `viewID`'s raw value is "whippet.terminal", pane index unset | `paneAccessibilityIdentifier` == "pane.terminal" |
| ctpvc-014 | accessibility-id-includes-pane-index | Same as above, pane index = 2 | `paneAccessibilityIdentifier` == "pane.terminal.2" |
| ctpvc-015 | pane-index-update-is-idempotent | Assign the pane index to 3 twice in a row on a loaded view, while observing writes to the container view's accessibility identifier | The observer records exactly one write, not two |
| ctpvc-016 | pane-index-update-refreshes-identifier | Assign the pane index to 1, then to 2, on a loaded view | The container's accessibility identifier updates to reflect index 2 |
| ctpvc-017 | arrange-mode-change-scoped-to-own-window | Post the arrange-mode change notification with a different window as its object | This pane's overlay state is unchanged |
| ctpvc-018 | layout-change-refreshes-overlay-globally | Pane A has an overlay installed in window 1; post the layout-change notification from a change made in window 2 | Pane A's overlay availability is refreshed |
| ctpvc-019 | window-close-removes-overlay | Overlay installed; close the pane's own window | The overlay is removed and its key-event interception is torn down |
| ctpvc-020 | pane-appearance-reevaluates-overlay | Arrange mode already enabled for the window before the view appears (e.g. after a move rebuild) | The overlay is installed by the time the view finishes appearing |
| ctpvc-021 | overlay-tracks-arrange-mode | Toggle arrange mode on, then off, for the pane's window | Overlay is installed on enable, removed on disable |
| ctpvc-022 | overlay-install-idempotent | Install the overlay twice in a row while arrange mode stays enabled | Exactly one overlay view exists; the second call only refreshes availability |
| ctpvc-023 | overlay-inset-from-border | Overlay installed | Its four edge constraints each use a constant of 2pt from the pane's view |
| ctpvc-024 | overlay-shows-pane-name | The pane's resolved title == "Terminal" when the overlay installs | Overlay's `paneName` == "Terminal" |
| ctpvc-025 | overlay-add-availability | Enclosing split reports zero legal, non-placeholder insertions | Overlay's Add control is disabled |
| ctpvc-026 | overlay-remove-availability | Enclosing split reports this pane cannot be removed as a leaf | Overlay's Remove control is disabled |
| ctpvc-027 | overlay-move-availability | Enclosing split reports Left and Right as the only legal move directions for this pane | Overlay offers exactly Left and Right as enabled moves |
| ctpvc-028 | overlay-done-disables-arrange-mode | Activate the overlay's Done control | Arrange mode becomes disabled for the pane's window |
| ctpvc-029 | overlay-installs-key-monitor | Install, then remove, the overlay | Key-event interception exists after install and is removed after removal |
| ctpvc-030 | exit-keys-disable-arrange-mode | Arrange mode enabled in the pane's window; press the Escape key while that window has focus | Arrange mode becomes disabled; the event is consumed (not passed through) |
| ctpvc-030b | exit-keys-disable-arrange-mode | Same setup; press the Return key | Arrange mode becomes disabled; the event is consumed |
| ctpvc-030c | exit-keys-disable-arrange-mode | Same setup; press the Enter key | Arrange mode becomes disabled; the event is consumed |
| ctpvc-031 | arrow-key-moves-active-pane-only | Arrange mode enabled; this pane is the window's active pane; press the Up arrow key | The pane moves up and the event is consumed |
| ctpvc-031b | arrow-key-moves-active-pane-only | Same setup, but this pane is NOT the window's active pane | No move occurs; the event is not consumed |
| ctpvc-032 | key-monitor-ignores-other-windows | Press a matching key while a different window than the pane's has focus | No action taken; event left unconsumed |
| ctpvc-033 | move-delegates-to-split | Request a move to the right; the enclosing split allows it | The enclosing split is asked to move this pane to the right, and no refusal is announced |
| ctpvc-034 | move-refusal-announced | Enclosing split refuses a move to the right | A refusal is announced exactly once |
| ctpvc-035 | gear-menu-move-submenu | Build the gear menu's items | Returns exactly one item titled "Move" whose submenu has four items, one per direction |
| ctpvc-036 | gear-menu-move-enablement | All four submenu items disabled | The "Move" item itself is disabled |
| ctpvc-036b | gear-menu-move-enablement | Exactly one of the four submenu items enabled, the rest disabled | The "Move" item itself is enabled |
| ctpvc-037 | add-choices-exclude-placeholder | Enclosing split reports a legal insertion for the placeholder view id | That insertion is excluded from the computed choices |
| ctpvc-038 | add-choices-deduplicated | Enclosing split reports the same non-placeholder view id insertable in two directions | The computed choices contain exactly one entry for that view id |
| ctpvc-039 | add-refused-when-empty | Computed choices are empty | Requesting Add announces a refusal and presents no picker |
| ctpvc-040 | add-picker-presentation | Overlay installed, exposing an Add-button anchor | Picker is presented as a popover anchored to that view |
| ctpvc-040b | add-picker-presentation | No overlay installed | Picker is presented as a sheet |
| ctpvc-041 | add-selection-splits-pane | Picker returns a chosen view id and the right direction | Enclosing split is asked to split this pane, inserting that view id to the right |
| ctpvc-042 | remove-refused-when-not-removable | Enclosing split reports this pane cannot be removed as a leaf | Requesting Remove announces a refusal and does not remove the pane |
| ctpvc-043 | remove-skips-confirmation-when-silent | Content offers no removal-confirmation message | The pane is removed immediately with no alert shown |
| ctpvc-044 | remove-confirms-when-content-warns | Content's removal-confirmation message is "Unsaved changes will be lost." | A warning alert is shown titled "Remove this pane?" with that message and Remove/Cancel buttons |
| ctpvc-045 | remove-confirmation-modal-without-window | Pane has no window; the user picks the first (Remove) button | The pane is removed |
| ctpvc-045b | remove-confirmation-modal-without-window | Pane has no window; user picks Cancel | The pane is not removed |
| ctpvc-046 | remove-confirmation-sheet-reresolves-split | Pane has a window; the enclosing split changes while the confirmation sheet is up; user picks Remove | The pane removes itself from the split resolved at sheet-completion time, not the one captured before the sheet opened |
| ctpvc-047 | removal-notifies-content-teardown | Content implements the teardown capability; the pane is removed | The overlay is removed and the content is notified that it will be discarded |
| ctpvc-048 | state-owner-retargets-store | Set `stateOwnerNodeID = X` | The pane's persisted-state store is retargeted to attribute state to `X` |
| ctpvc-049 | focus-check-skips-unloaded-view | View not yet loaded; check whether this pane contains the input focus | Returns false; the view is not force-loaded as a side effect |
| ctpvc-050 | focus-check-walks-hierarchy | View loaded; the window's focused element is nested inside this pane's view | The focus-containment check returns true |
| ctpvc-050b | focus-check-walks-hierarchy | View loaded; the window's focused element belongs to a different pane | The focus-containment check returns false |
| ctpvc-051 | title-bar-bottom-constant | Read `titleBarBottom` | Equals 28 (2pt border inset + 26pt title bar height) |
| ctpvc-052 | active-pane-cue-is-color-only | Compare the backdrop's drawn border for the active pane vs. an inactive one | `borderWidth` is 2 in both; only `borderColor` differs |
| ctpvc-053 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

