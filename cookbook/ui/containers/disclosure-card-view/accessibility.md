
- **Role/trait**: The card itself sets no accessibility role override — it
  is a plain container. The disclosure control is the platform's native
  disclosure control, which is exposed with its own native disclosure
  accessibility role and behavior. The status badge is explicitly given an
  image accessibility role (`exposes-status-as-own-accessibility-element`),
  and so is the title status symbol unless it holds a placeholder, which is
  no accessibility element at all (`exposes-title-status-like-badge`,
  `reserves-placeholder-room-silently`).
  The title, subtitle, and summary text elements carry no role override, so
  the platform's default static-text exposure applies to each.
- **Label requirements**: The disclosure control's accessibility label is
  set to `"Show details"`/`"Hide details"` at construction
  (`labels-disclosure-control`). The status badge's accessibility label is
  `status.accessibilityLabel`, doubling as its tooltip, and the title
  status symbol's is `titleTrailingStatus.accessibilityLabel`, likewise
  doubling as its tooltip; a placeholder has neither. The title, subtitle,
  and summary text elements carry no separate accessibility label; their
  displayed text is what a screen reader reads, per the platform's default
  label exposure.
- **Announce state changes**: The disclosure control's tooltip and
  accessibility label are fixed at construction to the `isCollapsed` value
  it was constructed with, and are never reassigned when the control is
  activated (see `does-not-self-mutate-on-toggle`). The platform's native
  disclosure control still flips its own visual indicator (and its native
  accessibility value) immediately on activation, so between an activation
  and the host's rebuild the tooltip/label text can read stale relative to
  the indicator's own state — this is resolved by the intended integration
  pattern (the host rebuilds the card on every toggle; see Design
  Decisions), not by anything internal to this component.
- **Minimum tap target**: Not applicable — this card is designed for a
  pointer/trackpad-driven interface; the disclosure control is the
  platform's native disclosure control at its default control size with no
  explicit width/height override, so its click target is whatever the
  platform's system disclosure control natively provides. The 44×44pt
  minimum is touch-interface guidance, not a pointer-interface requirement.
- **minimum-contrast-ratio**: The card draws every color from the active theme's semantic palette (surface, outline, primary text and the like) and performs no contrast check of its own; the contrast of title-on-titlebar, subtitle-on-surface and summary-value-on-surface pairings is whatever the active theme's resolved colors produce.

