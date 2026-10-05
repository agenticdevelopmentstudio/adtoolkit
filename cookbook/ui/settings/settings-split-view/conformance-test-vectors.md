
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-view-controller-001 | exposes-hosted-panels-read-only | Attempt to assign the panel list directly from outside the type | Compile error; only the set/add/remove/clear operations compile |
| split-view-controller-002 | default-detail-minimum-thickness | Construct a plain instance | The detail-pane minimum-thickness floor is `400` |
| split-view-controller-003 | overridable-detail-minimum-thickness | Subclass and override the detail-pane minimum-thickness floor to `200` | The overridden value, not `400`, governs the detail item's minimum thickness |
| split-view-controller-004 | default-sidebar-autosave-name | Construct a plain instance | The sidebar persistence key is `"ComposableSettings.RootSidebar"` |
| split-view-controller-005 | default-content-sized-sidebar | Construct a plain instance | The content-sized-sidebar flag is `false` |
| split-view-controller-006 | injectable-list-view-controller | Construct with a given custom panel-list subtype | The stored panel list is that exact same instance |
| split-view-controller-007 | reaches-list-controller-title | Set the sidebar title to `"Advanced"` after the view has loaded | The panel list's title becomes `"Advanced"` |
| split-view-controller-007b | reaches-list-controller-title | Set the sidebar title to `"Advanced"` before the view loads, then trigger the load step | The panel list's title is `"Advanced"` after load |
| split-view-controller-008 | reports-innermost-panel-title | Select a nested settings-split-view panel whose own current-panel-title is `"Accent Color"` | This instance's current-panel-title is `"Accent Color"` |
| split-view-controller-011 | forwards-help-presenter-to-detail-chrome | Set the help presenter to a given presenter | The detail-pane host's help presenter is that same presenter |
| split-view-controller-012 | forwards-inline-help-button-visibility | Set the inline-help-button-visibility flag to `false` | The detail-pane host's help-button-visibility flag is `false` |
| split-view-controller-013 | wires-help-visibility-callback-once | Assign the help-visibility-change callback twice, then have the detail-pane host fire its own callback | The most recently assigned closure fires; no double invocation and no re-wiring occurs on assignment |
| split-view-controller-014 | toggles-help-through-detail-chrome | Call the toggle-help operation | The detail-pane host's own toggle-help operation is invoked |
| split-view-controller-015 | reports-help-visibility-from-detail-chrome | Set the detail-pane host's help to visible | The help-visibility query returns `true` |
| split-view-controller-016 | builds-search-field-lazily | Construct an instance with search disabled and never read the search field | No search field is ever allocated |
| split-view-controller-017 | installs-search-field-only-when-enabled | Enable search before the view loads, then load | The panel list's header accessory is the search field |
| split-view-controller-017b | installs-search-field-only-when-enabled | Leave search disabled, then load | The panel list's header accessory is unset |
| split-view-controller-018 | filters-list-as-user-types | Type `"a"` into the search field without pressing Return | The panel list's search query is `"a"` immediately |
| split-view-controller-019 | redirects-arrow-keys-to-selection | With the search field focused and `"Advanced"` typed, press Down | Sidebar selection moves to the next visible row; search text remains `"Advanced"` |
| split-view-controller-020 | builds-non-collapsible-sidebar-item | Load the view, then attempt to collapse the sidebar item | Collapse is refused; the sidebar item cannot collapse |
| split-view-controller-021 | prioritizes-detail-pane-on-resize | Read the sidebar item's and detail item's resize-holding priority after the view loads | The sidebar item's priority is one step higher than the detail item's |
| split-view-controller-022 | fixes-content-sized-sidebar-thickness | Set the content-sized-sidebar flag to `true`, then load | The sidebar item's minimum thickness equals its maximum thickness |
| split-view-controller-023 | constrains-draggable-sidebar-range | Load with the content-sized-sidebar flag `false` (default) | The sidebar item's minimum thickness is `160`, maximum is `360` |
| split-view-controller-024 | persists-draggable-sidebar-width | Load with the content-sized-sidebar flag `false` | The sidebar's dragged width is persisted under the sidebar persistence key |
| split-view-controller-024b | persists-draggable-sidebar-width | Subclass overrides the sidebar persistence key to return none; load with the content-sized-sidebar flag `false` | No persistence key is set; width persistence is silently disabled, no fallback name is used |
| split-view-controller-025 | omits-autosave-for-content-sized-sidebar | Load with the content-sized-sidebar flag `true` | No persistence key is set |
| split-view-controller-026 | caps-content-sized-sidebar-width | The panel list's preferred width is `900`, no minimum-width override supplied | The sidebar item's fixed width is `480`, not `900` |
| split-view-controller-027 | unifies-nested-sidebar-widths | Host two nested settings-split-view panels whose own preferred widths are `180` and `220` | Both nested panels' minimum-sidebar-width override is `220` |
| split-view-controller-028 | raises-detail-floor-for-nested-siblings | Nested siblings as above, each with a detail-minimum-thickness floor of `200` | This instance's nested-detail floor is `420` (`220 + 200`) |
| split-view-controller-029 | floors-detail-pane-thickness | Detail-minimum-thickness floor is `400`, nested-detail floor is `420` | The detail item's minimum thickness is `420` |
| split-view-controller-030 | selects-first-panel-on-first-appearance | Set two panels, then trigger the view's first-appearance step with no prior selection | The first panel is shown and selected |
| split-view-controller-031 | repaints-theme-on-appearance-and-change | Switch the active theme after the view has appeared | Window and detail-container backgrounds update to the new theme's window-background color role |
| split-view-controller-032 | replaces-panel-list-atomically | Replace the panel list with `[a, b]` | The stored panels are `[a, b]`; history is empty; sidebar shows exactly `a` and `b` |
| split-view-controller-033 | appends-without-unnecessary-history-reset | With sort-by-title off, navigate to panel `a`, then add panel `c` | History still shows `a` as current; `c` appended at the end |
| split-view-controller-033b | appends-without-unnecessary-history-reset | With sort-by-title on, navigate to panel `a`, then add panel `c` where `c` sorts before `a` | History is reset; the sidebar re-selects `a` at its new (shifted) index |
| split-view-controller-034 | removes-and-renumbers-selection | Panels `[a, b, c]`, `b` selected, remove `a` | The stored panels are `[b, c]`; `b` remains selected at its new index `0` |
| split-view-controller-034b | removes-and-renumbers-selection | Panels `[a, b]`, `b` selected, remove `b` | Detail pane is cleared; nothing is selected |
| split-view-controller-035 | sorts-panels-when-configured | Sort-by-title on; add panels titled `"Zebra"`, `"Apple"` with no section | The stored panel order is `["Apple", "Zebra"]` |
| split-view-controller-036 | clears-search-when-restored-selection-is-hidden | Search query hides the currently selected panel, then removing a panel triggers a restore of that same panel | Search query is cleared before the panel is re-selected |
| split-view-controller-037 | clears-all-panels | Clear the panel list | The stored panels are `[]`; detail pane empty; navigation-change notification invoked |
| split-view-controller-038 | records-explicit-selection | Select the panel at index `1` | History's current index is `1` |
| split-view-controller-039 | steps-through-visible-rows-only | Visible rows are `[0, 2]` (row `1` filtered out), current is `0`, move the selection forward by one step | Selection moves to row `2`, not row `1` |
| split-view-controller-039b | steps-through-visible-rows-only | Current selection is the last visible row, move the selection forward by one step | No change; selection does not wrap to the first row |
| split-view-controller-040 | preserves-search-during-arrow-navigation | Search query is `"a"`, move the selection forward by one step | The panel list's search query remains `"a"` |
| split-view-controller-041 | navigates-back-through-history | History has one prior entry, navigate back | The previous panel is shown; history is not appended |
| split-view-controller-042 | navigates-forward-through-history | After navigating back, navigate forward | The panel that was current before navigating back is shown again |
| split-view-controller-043 | resolves-arrows-to-innermost-active-split | A nested split's own history can go back but the outer split's cannot, navigate back on the outer split | The nested split's back-navigation behavior runs, not the outer split's |
| split-view-controller-044 | clears-search-on-programmatic-navigation | Search query is `"a"`, navigate back | Search field and search query are cleared before the panel is shown |
| split-view-controller-045 | propagates-navigation-change-upward | This instance is nested inside an outer split, selection changes | Both this instance's navigation-change notification and the outer split's navigation-change handling fire |
| split-view-controller-046 | reports-current-panel-from-detail-container | Show panel `a` | The current-panel query returns `a` |
| split-view-controller-047 | reports-effective-help-from-current-panel | The current panel's effective help content is non-empty | The effective-help query returns that same value |
| split-view-controller-048 | refreshes-help-through-detail-chrome-and-outward | This instance is nested, refresh help | The detail-pane host's set-help operation is called with the effective-help value; the outer split's refresh-help operation is also called |
| split-view-controller-049 | hosts-self-managing-panels-without-wrapper | Show a panel that is itself a settings split view | The detail-pane host's content is that panel's view directly, no scroll wrapper |
| split-view-controller-050 | wraps-other-panels-in-scroll-view | Show a plain panel that does not host its own scrolling | The detail-pane host's content is a panel scroll wrapper wrapping that panel's view |
| split-view-controller-051 | updates-help-and-floor-on-every-show | Show no panel | The detail-pane host's content and help are both cleared, and the detail-floor recompute runs |
| split-view-controller-052 | locates-enclosing-split-by-parent-chain | This instance is added as a panel of an outer settings split view | The enclosing-settings-split query returns that outer instance |
| split-view-controller-053 | (edge case: removing a non-member panel) | Panels `[a, b]`, remove `z` where `z` is not in the panel list | The stored panels are unchanged (`[a, b]`); navigation history is still reset, the sidebar's panel list is still re-set, and the navigation-change notification still fires |
| split-view-controller-054 | (edge case: stale nested-detail floor) | Two nested settings-split-view siblings raise the nested-detail floor to `420`; removing a panel drops the nested count to one | The nested-detail floor remains `420` (not reset toward `0`), because the unification step's early exit returns before recomputing it |
| split-view-controller-055 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

