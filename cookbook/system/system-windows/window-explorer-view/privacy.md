
- **Data collected**: the view reads, but does not persist, information
  about currently running windows — application names, window titles
  (system-reported and, where matched, Accessibility-enriched), point
  frames, process ids, and on-screen/layer state — via the contexts
  model's window list and direct Accessibility and running-application
  queries. It also reads `appState.settings.hiddenApps` to filter the scan.
- **Storage**: none owned by this view. Scan results live only in
  local view state (`appGroups`, `isLoading`, `needsAccessibility`) for as
  long as the view exists; the selection set itself is owned by the caller
  through the `selectedWindowIDs` binding, so any persistence of a
  selection happens outside this component.
- **Transmission**: none. No networking import or call appears anywhere in
  this file; every API used (window enumeration, Accessibility queries,
  running-application queries) is a local, on-device system query.
- **Retention**: scan results are discarded and rebuilt on every
  window-scan call and are not retained once the view is deallocated.

