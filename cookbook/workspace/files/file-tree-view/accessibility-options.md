
- **Reduce Motion**: Not applicable. This component performs no animation of
  any kind — every reload, expansion, collapse, and recolor is an immediate
  property or layout change, with no transition or opacity fade to
  substitute (see Platform Notes for the Apple-specific animation API this
  deliberately avoids).
- **Increase Contrast**: Not applicable at this component's level. All
  non-git colors are semantic theme roles (`.primaryText`, `.secondaryText`,
  `.tertiaryText`, `.accent`, `.info`, `.warning`); this component contains no
  contrast-specific branching of its own, so any adaptation lives in the
  theme/palette system, not here. Git-status colors are the one exception:
  they are treated as "git's own vocabulary, not app chrome," kept as fixed
  colors rather than being remapped onto theme roles.
- **Differentiate Without Color**: Supported. Git status is always shown as a
  status letter (`M`, `A`, `D`, `R`, `C`, `?`, `U`, `!`) in addition to color,
  never by color alone; the dirty marker is a shape whose presence or absence
  carries the meaning, not a color change on an otherwise-identical shape.

