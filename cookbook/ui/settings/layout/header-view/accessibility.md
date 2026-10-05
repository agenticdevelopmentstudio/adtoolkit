
- **Role/trait**: Not set explicitly — no accessibility role override is
  applied to either the component or its label. The platform's default for
  a non-editable text element is a static-text accessibility element, so a
  screen reader exposes the label's text as static text without any
  additional code; the label captions a settings group but is not exposed
  as a heading, so a screen-reader user cannot jump between groups by
  heading.
- **Label requirements**: The label's displayed text (set from the
  caller-supplied `title` parameter) is both the visible text and, via the
  platform's default accessibility behavior, the accessible name — there is
  no separate accessible label set, and none is needed since the visible
  text and the accessible content are the same string.
- **Announce state changes**: Not applicable — the component defines no
  state that changes (see States); there is nothing for a screen reader to
  announce.
- **Minimum tap target**: Not applicable — the component is not an
  interactive control. It wires no target/action or gesture recognizer to
  it, so it has no tap target to size.

