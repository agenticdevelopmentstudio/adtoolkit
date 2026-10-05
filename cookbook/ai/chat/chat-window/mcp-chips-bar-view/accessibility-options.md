
- **Reduce Motion**: Not applicable — no animation or transition is
  triggered anywhere in source; the popover's presentation and dismissal
  transition is the platform's own system chrome, not custom motion
  authored by this file.
- **Increase Contrast**: Not applicable — every color used here
  (`theme.secondaryText`, `theme.accent`, and the primary text/background
  colors inherited from the shared theming mechanism) resolves through the
  shared theme palette; any Increase Contrast adaptation is that shared
  palette's responsibility, not a color this file hardcodes.
- **Differentiate Without Color**: Satisfied — the active-server count and
  the "none"/"No MCP servers" states are conveyed through text, and each
  row's active state is conveyed by the checkbox toggle's checkmark glyph,
  not by color alone.

