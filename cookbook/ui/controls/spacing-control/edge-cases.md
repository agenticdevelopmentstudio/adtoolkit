
- **Null/empty input**: `style` and `range` are required parameters with no
  empty/absent form, so the component needs no nil-handling path for them.
  `value` defaults to an all-zero spacing when omitted.
- **Boundary values — value at the range's floor or ceiling**: An arrow,
  stepper, drag, or committed field write MUST NOT move a value past the
  range's lower or upper bound; every write path clamps to that range.
- **Boundary values — zero-width gutter**: At a `betweenColumns` or
  `betweenRows` value of `0` in the `paneDividers` style, the diagram MUST
  still draw a `1pt` hairline gutter rather than a zero-width one, so the
  four-pane picture stays legible at the floor of the range.
- **Boundary values — `value` assigned outside range**: Assigning `value`
  directly to a number outside the range MUST NOT be rejected or re-clamped
  by the control itself — only *user-driven* edits are clamped. The
  diagram's **displayed** extent for that number is still capped at the
  maximum displayed inset (see caps-displayed-inset-at-maximum); the
  stepper showing that number is clamped to its own minimum/maximum, which
  are set from the range at construction.
- **Concurrent access**: Not applicable — the component runs entirely on a
  single UI thread by construction, and the drag-tracking loop runs
  synchronously to completion on that same thread before returning.
- **Error states**: Not applicable — every operation in source (formatting,
  clamping, layout, drawing) is synchronous and cannot fail; no
  error-producing path exists anywhere in this file.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking of its own.
- **A still trackpad press is not silence**: A press is watched for `0.12`s
  of stillness before being handed back to the arrow underneath, but a
  resting trackpad delivers a steady trickle of sub-`3pt` jitter events,
  each of which would otherwise restart that wait forever. The whole
  decision is bounded at `0.3`s regardless of how many such events arrive,
  so a held-still press on a trackpad still resolves and reaches the
  arrow's own repeat behavior, the same as a mouse's genuinely-silent hold
  does after the `0.12`s alone. This is a documented, source-traceable fix
  for a real input-device difference, not a hypothetical.
- **A field's mid-edit text is not clobbered by a sibling's change**: A
  field currently being edited keeps its uncommitted text when a
  *different* field's value changes and triggers a redisplay; only the
  field whose own number moved, or the field just committed, has its text
  rewritten.

