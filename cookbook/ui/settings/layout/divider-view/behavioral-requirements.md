
- **constrains-height-to-divider-thickness**: The component MUST fix its
  height to the divider-thickness design token (1.0pt) at initialization.
- **applies-divider-color-on-init**: The component MUST apply the resolved
  palette's divider color to its fill immediately upon construction.
- **resolves-color-through-nearest-theme-scope**: Whenever the component
  applies its divider color (on initialization, on a theme change, on its
  own scope's change, or on a repaint), it MUST resolve the color from the
  nearest enclosing theme scope's palette — walking outward from itself to
  find the nearest ancestor declaring a scope, and falling back to the
  app-wide scope when none exists.
- **reapplies-divider-color-on-theme-change**: The component MUST reapply
  its divider color from the resolved palette whenever the active theme
  changes.
- **reapplies-divider-color-on-own-scope-change**: The component MUST
  reapply its divider color from the resolved palette when its own
  resolved theme scope changes.
- **ignores-other-scope-change-notifications**: The component MUST NOT
  reapply its divider color when a theme scope other than its own resolved
  scope changes.
- **retains-theme-observer-for-view-lifetime**: The component's
  theme-change and scope-change repaint subscriptions MUST remain active
  for as long as the component exists, with no separate reference to an
  observer required from the caller.
- **ignores-settings-layout-changes**: The component's height MUST NOT
  update after initialization if the divider-thickness design token
  changes later; the height stays fixed to the value read once at
  construction time.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

