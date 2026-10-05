
- Pause and Clear are buttons (via the themed secondary button) constructed
  with a non-empty title (`Pause`/`Resume`, `Clear`), so the platform's
  default accessibility exposes each button's own title text as its
  accessible name; no explicit accessibility label or identifier call is
  made.
- Both buttons are standard buttons in the default key-view/tab-focus loop,
  so they receive Tab-key focus and Space/Return activation from the
  platform's ordinary focus and activation handling; no custom key
  equivalent is assigned to either.
- The status dot is a plain view with no accessibility role, label, or
  identifier of its own; its state is exposed through text instead (see
  **connection-state-in-text**).
- A connection-state change rewrites the status label's text, but no
  accessibility-announcement call accompanies it, so a screen-reader user
  currently gets no announcement when the stream connects, reconnects, or
  fails.
- Not applicable: minimum tap target. This is a pointer-driven control,
  not a touch surface, so the template's 44×44pt touch-target guidance
  does not apply; the toolbar buttons get no explicit width/height beyond
  the themed secondary button's own title-driven intrinsic size.
- **contrast**: the status dot's `.success`/`.warning`/`.danger` fills and the status label's `.secondaryText`-on-`.windowBackground` text pairing MUST come from the active theme palette; the component performs no contrast check of its own (see Design Decisions).

