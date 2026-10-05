
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pvc-001 | state-store-injection | Construct a pane with no state-store argument | The state store is an ephemeral (in-memory) state-store instance |
| pvc-003 | host-weak-reference | Assign the host, then release every other strong reference to that host object | The pane's host reference becomes empty |
| pvc-004 | close-is-a-request | Click the title bar's close button | The host's close-request is invoked once; no pane state changes |
| pvc-005 | zoom-is-a-request | Click the title bar's zoom button | The host's zoom-request is invoked once; the pane's zoomed state remains `false` |
| pvc-006 | minimize-picker-uses-host-edges | The host reports that minimizing is currently allowed only to the top and bottom edges; click the minimize button | The picker offers exactly those two edges enabled, with every other edge (e.g. leading) disabled |
| pvc-007 | minimize-pick-is-a-request | Open the minimize picker; pick the leading edge | The host's minimize-request is invoked with the leading edge; the pane's recorded minimize edge remains unset |
| pvc-008 | restore-is-a-request | Minimize the pane to the trailing edge; click the rail's restore button | The host's restore-request is invoked once |
| pvc-009 | host-change-refreshes-controls | Set the host to one that currently allows no minimize edges | The minimize button is disabled immediately after the assignment, with no further call needed |
| pvc-010 | close-availability-defaults-true | A pane with no host assigned | The close control is available |
| pvc-011 | minimize-availability-empty-without-host | A pane with no host assigned | The minimize button is disabled |
| pvc-012 | title-bar-above-content | Load the pane's view with a content inset of `0` | The title bar's top/leading placement and the content container's top placement (against the title bar's bottom) all resolve with a `0` offset |
| pvc-013 | content-child-hierarchy | The content-building hook returns content | The pane's children include it; its view is pinned to all four edges of the content container by exactly four active constraints |
| pvc-014 | no-content-is-supported | The content-building hook returns nothing (the default) | The pane's view loads without error; the pane has no content |
| pvc-015 | accessibility-id-on-container | Load a pane whose accessibility-identifier hook is not overridden | The container's accessibility identifier reads "pane" |
| pvc-016 | clamped-pane-yields-width | Set the clamping option to enabled before loading the view (this takes effect immediately), then load it | The title bar's, and its close button's, horizontal compression-resistance priority is already at the lowest value before the view loads, and is still exactly that value — not reset or reapplied — after loading completes, confirming the effect ran exactly once |
| pvc-017 | clamp-covers-later-installed-chrome | Same setup, after the view finishes loading and installs the gear | The gear's horizontal compression-resistance priority is also at the lowest value |
| pvc-018 | clamp-is-one-way | Set the clamping option to enabled, then set it back to disabled | The title bar's compression-resistance priority remains at the lowest value, not restored to its original value |
| pvc-019 | title-follows-content, title-change-callback-installed | Content implementing the title-providing capability changes its title from "Files" to "Sources", then synchronously invokes its own title-change callback | The title bar already reads "Sources" by the time that callback call returns — updated synchronously in response to the callback, not via a poll or a later run-loop turn |
| pvc-021 | title-refresh-updates-three-readers | An options dialog is open; trigger a title refresh after the content's title changed | The title bar's title, the open dialog's heading, and the title-change notification all reflect the new title |
| pvc-022 | fallback-title-default | A pane overriding nothing | The fallback title reads "Pane" |
| pvc-023 | accessories-from-content | Content implementing the accessory-providing capability with one accessory view | The title bar's accessory views contain exactly one element, identical to the content's view |
| pvc-024 | gear-installed-trailing | Load any pane | The title bar has a gear view, and its layout pins it to the title bar's own trailing edge (the trailing slot), not merely somewhere in the bar |
| pvc-025 | gear-menu-order | A pane whose menu items are one "Move" item | The options menu's items read `["Move", "", "Settings…"]`, with the second item a separator |
| pvc-026 | bare-pane-menu-is-settings-only | A pane whose menu items are empty | The menu has exactly one item, titled "Settings…" |
| pvc-027 | menu-items-self-validate | Any pane's options menu | Each item's enabled state is decided by the item itself, not by a platform default validation pass |
| pvc-028 | settings-opens-options-dialog | Choose "Settings…" from the gear menu | An options dialog is presented as a sheet, seeded with the pane's option rows and headed by its resolved title |
| pvc-029 | options-rows-order | Content implementing the options-providing capability with two rows | The option rows read as four rows: a spacing control, a reset control, then the content's two rows in order |
| pvc-030 | options-dialog-close-flushes-spacing | A spacing drag has a pending coalesced write; close the options dialog | The pending write reaches the state store before the dialog finishes closing |
| pvc-031 | spacing-defaults-to-inherited | Content not implementing the content-spacing-consuming capability, no stored override | The pane's inherited spacing is all-zero, unconditionally |
| pvc-032 | spacing-consumer-applies-its-own-gap | Content implementing the content-spacing-consuming capability | The resolved spacing is applied to the content itself; the pane's own content-spacing insets are all zero |
| pvc-033 | spacing-non-consumer-gets-pane-applied-gap | Content not implementing the content-spacing-consuming capability; a stored override of `top: 10` | The pane's own content-spacing insets read `top == 10` |
| pvc-034 | spacing-control-range | Build the spacing rows | The returned spacing control's underlying range is `0...40` |
| pvc-035 | spacing-reset-restores-inheritance | Set an override, then click "Use Default" | The stored override is deleted (not rewritten with the current inherited value); the reset button becomes disabled |
| pvc-036 | spacing-reset-enabled-only-when-overridden | Toggle between an overridden and a non-overridden spacing state, reapplying resolved spacing after each | The reset button's enabled state matches whether the spacing is currently overridden, at every check |
| pvc-037 | apply-resolved-spacing-is-idempotent | Reapply resolved spacing twice in a row with nothing changed in between | The spacing control's displayed value, the resolved spacing, and the content-spacing insets are all identical after both calls |
| pvc-038 | minimize-vertical-hides-content-only | Minimize to the top edge | The title bar stays visible; the content is hidden; the title bar's minimize control shows its minimized (restore) state |
| pvc-039 | minimize-horizontal-replaces-with-rail | Minimize to the leading edge | The title bar is hidden; a minimized rail exists among the pane's subviews |
| pvc-040 | rail-glyph-from-content | Content implementing the minimized-representation capability with symbol "folder"; minimize to the leading edge | The rail's icon reads "folder" and its tooltip equals the content's minimized tooltip |
| pvc-041 | rail-rebuilt-on-edge-change | Minimize to the leading edge, then directly to the trailing edge | Exactly one rail exists afterward; it is a different instance from the first, docked to the trailing edge |
| pvc-042 | restore-clears-minimized-chrome | Minimize to the leading edge, then restore | The minimize edge is cleared; the title bar becomes visible; no minimized rail remains among the subviews |
| pvc-043 | minimized-content-pins-deactivated | Minimize to the leading edge, then to the top edge | The count of active constraints pinning the content to the content container is `0` in both cases; it is `4` when whole |
| pvc-044 | minimize-before-load-is-lossless | Construct a pane; request minimizing to the leading edge before the view is touched; then load the view | The view stays unloaded until explicitly loaded; after loading, exactly one rail exists and the minimize edge reads leading |
| pvc-045 | appearance-methods-noop-before-load | Same setup as pvc-044, checked immediately after the minimize request and before loading | The view remains unloaded; no minimized rail has been created yet; the title bar's hidden state is untouched (nothing has run to hide or show it), because the appearance update returned immediately |
| pvc-046 | title-bar-trailing-active-except-rail | Force a layout pass at a fixed container width, after minimizing to the leading edge versus after minimizing to the top edge | The title bar's width equals the container's content width (minus insets) when minimized to the top edge; it is narrower than that after minimizing to the leading edge, because its trailing edge was released |
| pvc-047 | minimize-edge-persisted | Minimize to the bottom edge, against a store | The store's value for the minimize-edge key reads "bottom" |
| pvc-048 | zoom-persisted | Set zoomed to `true`, against a store | The store's value for the zoomed key reads "1" |
| pvc-049 | state-restored-on-load | Pre-populate a store with a minimize edge of "trailing" and zoomed "1"; load a pane against it | The pane's minimize edge reads trailing; its zoomed state reads `true` |
| pvc-050 | unparseable-stored-edge-ignored | Pre-populate a store with a minimize edge of "sideways"; load a pane against it | The pane's persisted minimize edge, and its minimize edge, both read as unset; no crash |
| pvc-051 | search-reaches-searchable-content-only | Content implementing the search capability; search for "main" | The pane is searchable; the content receives the query "main" |
| pvc-052 | selection-description-reported | Content implementing the selection-describing capability with a selection description of "README.md" | The pane's selection description reads "README.md" |
| pvc-053 | selection-change-forwarded | Set the selection-change callback; change the content's selection description | The callback fires exactly once |
| pvc-054 | minimized-thickness-formula | Content inset `0`; compute the minimized thickness for the leading edge and for the top edge | Returns `28` for the leading edge; returns `26` for the top edge |
| pvc-055 | spacing-clamped-on-read | Pre-populate a store with a spacing-override record encoding `top: 999` | The resolved spacing's top value is `40` (clamped into `0...40`), not `999` |
| pvc-056 | spacing-decode-failure-is-absent | Pre-populate a store with an unparseable spacing-override record | The spacing is treated as not overridden; the resolved spacing equals the inherited spacing |
| pvc-057 | search-reaches-searchable-content-only | Content not implementing the search capability; search for "main" | The pane is not searchable; the call neither crashes nor has any observable effect on the content |
| pvc-058 | selection-description-reported | Content not implementing the selection-describing capability | The pane's selection description is unset |
| pvc-059 | accessories-from-content | Content not implementing the accessory-providing capability; refresh accessories | The title bar's accessory views are empty |
| pvc-060 | rail-glyph-from-content | Content not implementing the minimized-representation capability; minimize to the leading edge | The rail's icon reads the generic default; its tooltip equals the pane's resolved title |
| pvc-061 | clamped-pane-yields-width | Construct a pane and never enable the clamping option, then disable it | The title bar's horizontal compression-resistance priority is unchanged from its default — the yield never occurs |
| pvc-062 | spacing-defaults-to-inherited | Content implementing the content-spacing-consuming capability with an inherited spacing of `top: 10, leading: 0, bottom: 0, trailing: 0`, no stored override | The pane's inherited spacing equals exactly the content's value, `top: 10, leading: 0, bottom: 0, trailing: 0` |
| pvc-063 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

