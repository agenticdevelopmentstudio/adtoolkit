
- **Role/trait**: An image accessibility role, set explicitly at
  construction.
- **Label requirements**: Satisfied unconditionally — the state-description
  logic sets the accessibility label to `"Working"`, `"Idle"`, `"Waiting for
  you"`, or `"Summarizing"` (see **state-based-label-and-tooltip**) every
  time the state is established (at construction) or actually changed (on
  update), so the label never describes a stale state. The same text is
  mirrored into the tooltip.
- **Announce state changes**: The state-description logic reassigns the
  accessibility label, tooltip, and accessibility identifier whenever
  `activity` or `isSummarizing` actually changes, but no explicit
  accessibility change notification accompanies that reassignment anywhere
  in the source — the change reaches assistive technology only through the
  platform's own default handling of a reassigned accessibility label, never
  through an explicitly posted notification.
- **Minimum tap target**: Not applicable in the touch sense — this is a
  pointer-driven, non-touch component with no interaction handling of any
  kind in the source; a touch platform's minimum tap-target size applies to
  touch targets, not to a static image-only display element.
- **theme-owned-tint-contrast**: The glyph's tint MUST come from the active theme's accent, tertiary-text or warning color role (or the system fallback) as an opaque fill; the component performs no contrast check of its own against the session row background behind it.

