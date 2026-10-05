
- **Reduce Motion**: Not applicable — applying the theme sets colors
  directly with no animation or transition of any kind; there is no motion
  for this setting to reduce.
- **Increase Contrast**: Not applicable in the sense of a distinct code path
  — the component performs no Increase-Contrast-specific branching of its
  own; all color comes from theme tokens whose values are outside this file
  (see Accessibility > the open question on contrast).
- **Differentiate Without Color**: The active/inactive distinction is
  conveyed by outline color alone (the active-pane-outline color vs. the
  pane-outline color); the source defines no secondary, non-color cue
  (outline width, an icon, a pattern, a label) and does not read the
  Differentiate Without Color setting. A non-color cue, if one is added, is a
  change to the theme-application drawing, not to the tracking logic this
  ingredient otherwise specifies.

