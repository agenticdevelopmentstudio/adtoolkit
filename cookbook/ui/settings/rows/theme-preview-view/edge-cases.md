
- Null/empty input: the theme defaults to none in the component's
  construction. When none is given, the container remains empty and the
  component's background is never painted until the show operation is
  called explicitly with a concrete theme — this is a MUST
  (empty-initial-state), not a crash or a placeholder theme.
- Boundary values — repeated/idempotent show: calling the show operation
  multiple times, including twice with the same theme, produces the same
  visual result each time because every call tears down all existing
  samples before rebuilding (show-teardown-and-rebuild). This is a MUST,
  traceable to an unconditional teardown-then-rebuild step at the top of
  the operation.
- Boundary values — long or narrow content: cards are forced to exactly
  the container's width (card-width-stretch), but no label anywhere in
  source sets line-wrapping, a maximum line count, or single-line-only
  behavior, so in a very narrow host or with an enlarged typography
  scale, list-row detail labels, badge text, or the chrome sample's
  content can be clipped or compressed rather than reflowed, per each
  plain label's platform default.
- Concurrent access: Not applicable — the component is confined to a
  single, serialized execution context, so every call to the show
  operation and every private sample-building helper is serialized; there
  is no code path by which two threads mutate the container simultaneously.
- Error states: Not applicable — every operation in the show operation and
  its helpers is a synchronous, non-throwing property assignment or view
  construction. The theme's terminal-appearance resolution (font, padding,
  cursor) is non-throwing and total over the theme and the app's stored
  defaults, and always resolves to a concrete value; no error or optional
  is propagated to this component from any of it.
- Offline/disconnected state: Not applicable — the component performs no
  networking of its own; it only renders values resolved from the supplied
  theme and local stored defaults.
- Quirk — swatch grid excluded from the width stretch: the show operation
  applies the width-stretch sizing only over the five sample boxes; the
  swatch grid appended afterward is never included in that sizing pass, so
  it is left at its own content-driven width. With the fixed 8-column
  layout and exactly 16 ANSI colors this always renders two full rows
  regardless, so the omission has no visible effect today, but it is a
  documented, source-traceable asymmetry rather than something this
  recipe assumes is intentional design.
- Quirk — chrome sample's divider/inner-panel width sizing references the
  outer box: the card-content-fill step returns the same box instance it
  was given (not a wrapper), which is what lets the divider's and the
  inner panel's width sizing — both applied after that fill step returns
  — resolve correctly against the final card width.

