
- **Reduce Motion**: Not applicable — no animation or transition is part
  of this component; every state change (label text, visibility, color
  role) is an instantaneous property assignment.
- **Increase Contrast**: Not applicable — the component sets no custom
  color of its own; the title, prompt, and validation message colors all
  come from the theme's role-based palette lookup, which follows the
  active theme/system Increase Contrast automatically. The field's
  coloring is the platform's own default control appearance, likewise
  system-managed.
- **Differentiate Without Color**: The validation message's three
  severities (error/warning/information) are distinguished only by color
  role in `showValidation(_:)` — no icon, prefix, or other non-color cue
  is added.

