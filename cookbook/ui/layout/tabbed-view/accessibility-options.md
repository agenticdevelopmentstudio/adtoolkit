
- **Reduce Motion**: Not applicable — this concept defines no animation or
  transition anywhere; every appearance change (selection restyle, thickness
  change, layout rebuild) applies immediately.
- **Increase Contrast**: Not applicable — every color this component draws
  (`selection`, `selectionText`, `secondaryText`, `tertiaryText`,
  `windowBackground`, `outline`) is a semantic palette role; increased-
  contrast handling, if any, belongs entirely to the theme/palette system
  this component defers to, not to this concept.
- **Differentiate Without Color**: The tab button distinguishes selected
  from unselected purely by fill color (`selection` vs. transparent) and a
  text-role swap (`selectionText` vs. `secondaryText`); no border, icon,
  weight, or other non-color cue accompanies the change. A content-hosting
  item on a vertical edge gets a color-independent stacking/overlap cue from
  its stack depth, but a title-only tab never gets one, on any edge.

