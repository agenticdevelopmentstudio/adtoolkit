
- **Reduce Motion**: The depth-change animation slides and resizes the
  card's paint and text boxes (a position *and* size change, not a plain
  opacity cross-fade) over `0.16s` whenever depth changes while the card is
  on screen; nothing in this component checks the system's Reduce Motion
  setting before running that animation, so a Reduce Motion user sees the
  same slide as anyone else.
- **Increase Contrast**: Not applicable — every color this component draws
  (`projectPaneBackdrop`, `projectPaneOutline`, `windowBackground`, `border`,
  `.accent`, `.primaryText`, `.secondaryText`, `.tertiaryText`) is a semantic
  palette role; Increase Contrast handling, if any, belongs to the
  theme/palette system this component defers to, not to this file.
- **Differentiate Without Color**: Supported. The front/behind distinction
  is never carried by color alone: a behind card is also drawn smaller and
  further from the workspace (recession, `≥ 4pt` on every side) and never
  overhangs the workspace's outline, while the front card does both — a
  geometry-based cue that accompanies every color change the appearance
  update makes.

