
- **Role/trait**: The component, the card, and the row area set no explicit
  accessibility role; each is exposed to assistive technology with the
  platform's ordinary default, not as a distinguished "group" container. The
  header view's own accessibility behavior belongs to that view (a static-
  text label); this component does not further style or role it.
- **Label requirements**: The component never associates the header/caption
  text with the card or the row area through any accessibility API — no
  explicit accessible label, no labelled-by relationship, no accessible
  group role. A settings group's entire visual purpose is a named card of
  rows, so a screen-reader user tabbing into the card's rows has no
  programmatic way to learn which caption group they belong to; only
  sighted proximity conveys that relationship.
- **Announce state changes**: Not applicable beyond the platform's own
  default — hiding a row's content sets that row's own hidden state, which
  removes it (and its content) from the accessibility tree automatically;
  the component performs no explicit screen-reader announcement of its own
  for a row appearing, disappearing, or a separator changing.
- **Minimum tap target**: Not applicable — the component, the card, and each
  row are layout/presentation containers with no target/action or gesture
  recognizer of their own; whatever tap targets exist belong to each row's
  own caller-supplied content and that content's own recipe.

