
- **Null/empty input**: The appearance defaults to a white color/white
  text with both flags `false` when the caller never sets it, resolving
  to a filled caret (see **default-fill**). This is the well-defined
  default, not an error condition.
- **Boundary values**: Not applicable — the only caller-supplied inputs
  are two colors and two boolean flags, none of which have a numeric
  range; the one numeric constant in the file, the outline width (`1`
  point), is fixed and not caller-configurable.
- **Concurrent access**: Not applicable — the component is confined to
  the UI's main execution context, so every mutation path (the
  appearance property's change handler, the notification subscription,
  and the cursor-shown/cursor-style-changed overrides) is confined there
  (see **confines-to-ui-thread**).
- **Error states**: WHEN the active-pane tracker's change notification
  does not name a window (including no window at all), the component
  MUST silently ignore the notification and take no action, per the
  type-checked guard in the subscription handler. There is no other
  error-producing dependency (no network, database, or file-system
  access) in this file, so Cookbook Compliance's networking/error-handling
  requirements are Not applicable here.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking; its only external interaction is a local notification
  publisher and view-hierarchy calls.
- **Caret subview not yet present**: The border-application step's guard
  against a missing caret subview makes border application a silent
  no-op rather than a crash (see **missing-caret-subview-tolerance**).
- **Caret subview rebuilt by the terminal engine**: WHEN the cached weak
  subview reference's superview is no longer this view, the component
  re-searches rather than reuses the stale reference (see
  **caret-subview-cache**).
- **View not yet embedded in any composable-tabs pane while the
  marks-active-pane flag is `true`**: the caret stays filled regardless
  of the marks-active-pane flag — only the always-hollow flag can force
  it hollow outside composable-tabs context — because
  `adtoolkit://cookbook/ui/layout/composable-tabs/active-pane#requirements/view-outside-any-pane-counts-as-active`
  treats such a view as always "in the active pane."
- **Multiple instances across different windows**: each instance ignores
  a change notification whose named window does not match its own
  window, so a pane-activation change in one window never repaints a
  caret in another (see **active-pane-notification-window-filter**).

