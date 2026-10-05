
- **Role/trait**: Every label exposes itself to a screen reader as static
  text by the platform's own default; no other element (box, pill, badge,
  row, the caret, the hairline) sets an accessibility role, marks itself
  as an accessibility element, or makes any similar call anywhere in
  source, so none of those containers expose a semantic grouping of their
  own. Neither the whole preview nor any sample card is combined into a
  single accessibility element with a summarizing label; a screen reader
  reads roughly twenty individual demo labels one at a time, with no
  indication they belong to a "theme preview" rather than live application
  state.
- **Label requirements**: All visible text is the literal English demo
  strings itemized in Behavioral Requirements (see also Localization); no
  accessible-label/accessible-value override is set anywhere, so a screen
  reader reads exactly that literal text. Nothing in source distinguishes
  illustrative sample text ("Window Title", "Success", "Documents") from a
  real value a user could act on — a screen reader has only that literal
  demo string to read either way.
- **Announce state changes**: Not applicable — the show operation is the
  only mutating entry point, runs synchronously to completion on a single,
  serialized execution context, and there is no loading indicator or
  asynchronous transition to announce (see States/Loading).
- **Minimum tap target**: Not applicable — this is a pointer/trackpad
  composition with no interactive element anywhere in source (see
  States/Pressed), so there is no touch target to size. The embedded
  swatch grid's own accessibility posture is documented in its own recipe
  (`adtoolkit://cookbook/ui/settings/rows/swatch-grid-view`), not
  repeated here.

