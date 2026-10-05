
- **Reduce Motion**: Not applicable — this concept defines no animation or
  transition anywhere; every appearance change (selection restyle,
  thickness change, layout rebuild) applies immediately.
- **Increase Contrast**: Not applicable — every color this component draws
  (`selection`, `selectionText`, `secondaryText`, `tertiaryText`,
  `windowBackground`) is a semantic palette role; increased-contrast
  handling, if any, belongs to the theme/palette system this component
  defers to, not to this concept itself.
- **Differentiate Without Color**: The tab button distinguishes selected
  from unselected purely by fill color (`selection` vs. transparent) and a
  text/icon color-role swap (`selectionText` vs.
  `secondaryText`/`tertiaryText`); the title label's text role (and
  therefore its font) never changes, so no weight, size, border, or icon
  accompanies the change, and this concept does not implement
  Differentiate Without Color support. A content-hosting item on a
  vertical bar gets a color-independent stacking/overlap cue from its
  stack depth, but a title tab never gets one, on any edge.

