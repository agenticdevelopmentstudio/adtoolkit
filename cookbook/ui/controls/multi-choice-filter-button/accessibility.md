
- **Role/trait**: Not customized in source — no explicit accessibility role
  assignment appears anywhere in this component's own source; the control
  inherits the platform's native pull-down accessibility role, and each
  entry inherits the platform's native checkable-menu-item semantics from
  its checked state.
- **Label requirements**: Not set via an explicit accessible-label
  override; a screen reader's accessible name comes from the platform's
  native title-based naming, and by construction (see
  **formats-title-none-selected** through **formats-title-many-selected**)
  that title always states both `label`, the axis being filtered, and the
  current selection state, so the accessible name is never a bare,
  contextless string.
- **Announce state changes (e.g., loading, disabled)**: Not customized in
  source — the title-refresh and checkmark-resync operations rely entirely
  on the platform's own native accessibility change notifications for this
  control and its menu items; this file posts no announcement of its own.
- **Minimum tap target**: Not applicable — this is a pointer/
  trackpad-driven control with no touch input path in source; a 44×44pt
  minimum is touch guidance that does not apply. Source sets no explicit
  control-size override, so it keeps the platform's regular system control
  metrics.
- **contrast**: The component performs no contrast check of its own. The foreground tint color (the theme's primary text color) and the button's bezel are both resolved from the active theme at runtime, so foreground-versus-bezel contrast is whatever each shipped theme produces.

