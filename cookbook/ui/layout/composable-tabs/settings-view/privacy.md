
- **Data collected**: None of its own. The component reads and writes local
  application settings only: per-edge tab-bar enablement (via the injected
  closures) and frame/divider spacing integers (via the app-wide spacing
  settings).
- **Storage**: Frame and divider spacing persist through the app-wide
  frame- and gutter-spacing settings, whose default storage survives an app
  restart, lives on the local device only (not synced by default), and is
  shared across every project window, not scoped to one project. The
  storage for tab-bar edge-enabled state is NOT decided by this component:
  it is owned entirely by whatever backs the injected
  `isEdgeEnabled`/`setEdgeEnabled` closures. The Tabs panel's own help text
  states these edges "belong to this project... and are saved with the
  project," implying project-file persistence, but the write path itself is
  outside this component.
- **Transmission**: Not applicable — no networking call appears anywhere in
  this component.
- **Retention**: Spacing settings are retained indefinitely until explicitly
  changed again or the settings store is reset; this component codes no
  expiry or automatic clearing. Retention of edge-enabled state is likewise
  outside this component's control.

