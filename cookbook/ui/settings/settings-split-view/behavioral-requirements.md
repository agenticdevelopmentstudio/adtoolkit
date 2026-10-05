
- **exposes-hosted-panels-read-only**: The component MUST expose its panel
  list as read-only to callers outside the type — mutable only through its
  own set/add/remove/clear operations.
- **default-detail-minimum-thickness**: The component MUST default its
  detail-pane minimum-thickness floor to `400` points when not overridden.
- **overridable-detail-minimum-thickness**: A subtype MAY override the
  detail-pane minimum-thickness floor to raise or lower the floor applied
  to the detail pane — appropriate when a subtype's own content needs a
  different minimum than the window-level default (a nested split lowers
  it to `200` for nested content; see that recipe).
- **default-sidebar-autosave-name**: The component MUST default its
  sidebar persistence key to `"ComposableSettings.RootSidebar"` when not
  overridden.
- **default-content-sized-sidebar**: The component MUST default its
  content-sized-sidebar flag to `false`.
- **injectable-list-view-controller**: The component MUST accept a panel
  list component (or subtype) at construction, defaulting to a stock panel
  list when the caller supplies none.
- **reaches-list-controller-title**: Whatever value the sidebar title
  holds MUST reach the panel list's own title — immediately, if the
  sidebar title is set after the view has loaded, or once, during the
  view's load step, if it was set (or left at its default) beforehand.
- **reports-innermost-panel-title**: The current-panel-title query MUST
  return the innermost selected panel's own title — recursing into a
  selected panel that is itself a settings split view and using its own
  current-panel-title — whenever that inner title is non-empty, rather
  than this instance's own selected panel's descriptor title.
- **forwards-help-presenter-to-detail-chrome**: Whenever the help
  presenter is set, the component MUST forward the new value to the
  detail-pane host's own help-presenter property.
- **forwards-inline-help-button-visibility**: Whenever the
  inline-help-button-visibility flag is set, the component MUST forward
  the new value to the detail-pane host's own help-button-visibility
  flag.
- **wires-help-visibility-callback-once**: The component MUST wire the
  detail-pane host's help-visibility-change callback to invoke its own
  help-visibility-change callback exactly once, during construction,
  rather than re-wiring it each time that callback is assigned.
- **toggles-help-through-detail-chrome**: Toggling help MUST delegate to
  the detail-pane host's own toggle-help operation.
- **reports-help-visibility-from-detail-chrome**: The help-visibility
  query MUST return the detail-pane host's own help-visibility value.
- **builds-search-field-lazily**: The sidebar search field MUST be built
  lazily, on first access, so a split with search disabled never
  allocates it.
- **installs-search-field-only-when-enabled**: During the view's load
  step, the component MUST install the search field as the sidebar's
  header accessory if and only if search is enabled at that moment.
- **filters-list-as-user-types**: The search field MUST report every
  keystroke immediately, not only on commit, and each report MUST set the
  panel list's own search query to the field's current text.
- **redirects-arrow-keys-to-selection**: While the search field holds
  focus, pressing Down or Up MUST move the sidebar selection by a step
  instead of moving the text caret; every other editing command MUST fall
  through to the field's default handling.
- **builds-non-collapsible-sidebar-item**: During the view's load step,
  the component MUST add a non-collapsible sidebar item hosting the panel
  list.
- **prioritizes-detail-pane-on-resize**: The sidebar item's
  resize-holding priority MUST be higher than the detail item's, so a
  window resize resizes the detail pane rather than the sidebar (see the
  source values in Platform Notes).
- **fixes-content-sized-sidebar-thickness**: Whenever the
  content-sized-sidebar flag is `true`, the component MUST set the
  sidebar item's minimum and maximum thickness to the same value (see
  **caps-content-sized-sidebar-width**), making the sidebar non-draggable.
- **constrains-draggable-sidebar-range**: Whenever the content-sized-
  sidebar flag is `false`, the component MUST constrain the sidebar
  item's thickness between `160` and `360` points.
- **persists-draggable-sidebar-width**: Whenever the content-sized-
  sidebar flag is `false`, the component MUST persist the sidebar's
  dragged width under the sidebar persistence key, so a user's dragged
  sidebar width survives across app launches.
- **omits-autosave-for-content-sized-sidebar**: Whenever the
  content-sized-sidebar flag is `true`, the component MUST NOT persist a
  dragged sidebar width.
- **caps-content-sized-sidebar-width**: A content-sized sidebar's
  thickness MUST equal the lesser of an externally supplied minimum-width
  override (or, absent one, the panel list's own preferred width) and
  `480` points.
- **unifies-nested-sidebar-widths**: Whenever two or more of this
  instance's hosted panels are themselves settings split views, the
  component MUST set every one of their minimum-sidebar-width overrides
  to the same value: the widest of their own preferred widths, capped at
  `480` points.
- **raises-detail-floor-for-nested-siblings**: Whenever
  **unifies-nested-sidebar-widths** applies, the component MUST raise its
  own nested-detail floor to the largest of `widest + nested's own
  detail-minimum-thickness` across those nested siblings.
- **floors-detail-pane-thickness**: The detail item's minimum thickness
  MUST always equal the larger of the detail-minimum-thickness floor and
  the nested-detail floor.
- **selects-first-panel-on-first-appearance**: During the view's
  first-appearance step, if no panel is yet selected and the panel list is
  non-empty, the component MUST select the first panel.
- **repaints-theme-on-appearance-and-change**: The component MUST repaint
  the window's background and the detail container's background from the
  active theme's window-background color role on every appearance and on
  every theme change it is notified of.
- **replaces-panel-list-atomically**: Replacing the panel list MUST
  replace the stored panels (ordered per **sorts-panels-when-configured**),
  reset navigation history, rebuild the sidebar, and re-run
  sidebar-layout unification, in that call.
- **appends-without-unnecessary-history-reset**: Adding a panel MUST
  append the given panel to the stored panels (reordering if
  **sorts-panels-when-configured** applies) and rebuild the sidebar
  without resetting navigation history, except that when panels are
  sorted by title it MUST reset history and restore the selection, because
  sorting may have renumbered existing rows.
- **removes-and-renumbers-selection**: Removing a panel MUST remove the
  given panel by identity, reset navigation history, rebuild the sidebar,
  and restore the sidebar's highlight to whichever panel remains selected
  at its new index — or clear the detail pane if the removed panel was the
  one on screen.
- **sorts-panels-when-configured**: Whenever panels are configured to
  sort by title, replacing or adding panels MUST order the full panel
  list by section (ranked in first-encountered order) and, within equal
  rank, by a locale-aware comparison of the descriptor's title; whenever
  that configuration is off, panels MUST keep exactly the order supplied.
- **clears-search-when-restored-selection-is-hidden**: When a rebuild's
  restored selection is not among the sidebar's currently visible
  (search-filtered) rows, the component MUST clear the sidebar search
  query before re-selecting it.
- **clears-all-panels**: Clearing the panel list MUST empty the stored
  panels, reset navigation history, empty the sidebar, empty the detail
  pane, and invoke navigation change notification.
- **records-explicit-selection**: Selecting a panel, by reference or by
  index, MUST record the target index in navigation history before
  showing it.
- **steps-through-visible-rows-only**: Moving the selection by a step
  count MUST move the selection only among the sidebar's currently
  visible (search-filtered) rows, and MUST stop at the first or last
  visible row rather than wrapping.
- **preserves-search-during-arrow-navigation**: Moving the selection by a
  step count MUST leave the search field's text and the panel list's
  search query unchanged.
- **navigates-back-through-history**: Navigating back MUST, when a back
  step exists on the innermost split still able to go back, show that
  split's previous panel without recording a new history entry.
- **navigates-forward-through-history**: Navigating forward MUST,
  symmetrically with **navigates-back-through-history**, show the next
  panel in the trail without recording a new history entry.
- **resolves-arrows-to-innermost-active-split**: Navigating back and
  navigating forward MUST act on the innermost nested split whose own
  history can still move in the requested direction, falling back to this
  instance when no nested split can.
- **clears-search-on-programmatic-navigation**: Showing a panel via
  navigating back, navigating forward, or selecting a panel (by reference
  or by index) MUST clear the sidebar search field and query first, so the
  target row is never hidden by a stale filter.
- **propagates-navigation-change-upward**: Whenever this instance's
  selection, history availability, or panel title changes, it MUST invoke
  its own navigation-change notification and MUST also invoke the
  enclosing settings split view's navigation-change notification, if one
  exists.
- **reports-current-panel-from-detail-container**: The current-panel
  query MUST always reflect whichever panel is currently hosted in the
  detail pane, recomputed from the detail pane's actual content rather
  than from any separately tracked selection state (see the source
  mechanism in Platform Notes).
- **reports-effective-help-from-current-panel**: The effective-help query
  MUST return the current panel's own effective help content.
- **refreshes-help-through-detail-chrome-and-outward**: Refreshing help
  MUST hand the effective-help value to the detail-pane host's own
  set-help operation and MUST also call the enclosing split's own
  refresh-help operation, if one exists.
- **hosts-self-managing-panels-without-wrapper**: Showing a panel MUST
  host it directly in the detail-pane host (no wrapping scroll view) when
  that panel is itself a settings split view or reports that it hosts its
  own scrolling.
- **wraps-other-panels-in-scroll-view**: Showing a panel MUST wrap every
  other panel's view in a panel scroll wrapper before hosting it in the
  detail-pane host.
- **updates-help-and-floor-on-every-show**: Every call to show a panel,
  including showing none, MUST refresh the detail chrome's help content
  and MUST re-apply the detail-pane minimum-thickness floor.
- **locates-enclosing-split-by-parent-chain**: The enclosing-settings-
  split query MUST always reflect the current containment hierarchy —
  recomputed from the live containment relationship each time it is read,
  not cached — returning none when no enclosing split exists (see the
  source mechanism in Platform Notes).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

