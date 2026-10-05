
- **Role/trait**: Not customized — no explicit accessibility role is set;
  the editor carries the platform's own built-in text-area accessibility
  role.
- **Label requirements**: The editor is labeled with the view model's title
  once, at construction (accessibility-label), so a screen reader announces
  the editor by the row's title. This does not go stale: the view model's
  title cannot change after construction — the same invariant that makes
  label-resync's repeated assignment always a no-op (see Design Decisions).
- **Announce state changes**: Not applicable — the component has no loading
  state and never disables itself (see States); typed and deleted characters
  are announced through the editor's own native accessibility value
  reporting, unmodified by the component.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition with no touch input path; the 44×44pt minimum is touch-
  interface guidance. The component's clickable area is the full scrolling
  container, sized by visible-height.
- **Keyboard navigation**: Not customized beyond the platform's defaults —
  no exclusion from the window's tab order appears, so the editor
  participates in the window's normal tab order like any other control.
  Within the editor, the platform's own default behavior inserts a tab
  character on Tab rather than moving focus to the next control — correct
  for a multi-line text/code editor, where a literal tab is valid content.
  The component does not itself document or test how a keyboard user leaves
  the editor once inside it; the platform's own default key-view-loop
  binding is what would apply, but nothing in the component asserts or
  overrides this, so it is recorded here as resting on a platform default
  rather than on this component (see Compliance: `keyboard-navigable` is
  `partial`, not `passed`, for this reason).
- **Contrast**: Not set independently by this component — the editor's
  typed text resolves to the theme's primary-text role (unchanged
  foreground; no minimum contrast computed for this role), matching the
  label. Whether an active theme's resolved primary-text-on-control-
  background pairing clears WCAG 2.1 SC 1.4.3's 4.5:1 threshold for normal
  text is a property of the chosen theme, not of this component.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label and the editor's text take the theme's primary-text role, drawn on the theme's control-background color, and the editor sets its own insertion-point and selection colors from the theme; contrast is whatever the active theme resolves.

