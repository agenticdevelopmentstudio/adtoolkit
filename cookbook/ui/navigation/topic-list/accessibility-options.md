
- **Reduce Motion**: Not applicable - source defines no animation or
  transition anywhere in this component; every state change (selection,
  resection, theme repaint) is an instantaneous property assignment or a
  synchronous reload.
- **Increase Contrast**: Not applicable to this component specifically -
  it never assigns a raw color literal; every color it uses is read from
  the active theme palette. Whether the active palette itself adjusts
  under Increase Contrast is that theme system's responsibility, not
  something this component decides or can override.
- **Differentiate Without Color**: Not implemented. A disabled item is
  distinguished from an enabled one only by color - the tertiary text
  color versus the primary text color/accent color (see
  **mute-disabled-item-appearance**) - with no accompanying non-color
  cue: no icon change, no strikethrough, and no opacity reduction, since
  full opacity is explicitly set for every row.

