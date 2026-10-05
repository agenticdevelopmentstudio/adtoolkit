
- **constructs-plain-text-field**: Component MUST construct its text field
  with the view model's current value as its initial content, via an
  overridable construction point whose default implementation returns a
  plain text field.
- **supports-text-field-substitution**: Component MUST expose that
  construction point as overridable, so a variant (such as a secure
  text-entry row) can substitute a different control type while reusing
  every other behavior unmodified.
- **arranges-row-layout**: Component MUST arrange the label and the text
  field in a single horizontal row (label, then text field), and MUST pin
  that row to the edges of the component.
- **expands-text-field-to-fill-row**: Component MUST size the text field so
  it — not the gap between it and the label — takes the width left over
  after the label (see Design Decisions for the specific mechanism and
  value).
- **wires-text-field-action**: Component MUST route the text field's
  edit-completion signal to itself, so a committed edit reaches the view
  model's committed value (see Platform Notes for the specific mechanism).
- **initializes-from-view-model**: Component MUST, during initialization,
  set the label's text to the view model's title and construct the text
  field with the view model's value as its initial value.
- **commits-value-on-change**: Component MUST write the field's current
  string value into the view model's committed value whenever the field's
  edit-completion signal fires and that value differs from the current
  committed value.
- **skips-redundant-commits**: Component MUST NOT write to the view model's
  committed value when the field's value equals the current committed
  value.
- **syncs-on-external-change**: Component MUST re-set the label's text to
  the view model's title and the field's string value to the view model's
  value whenever the view model's change notification fires.
- **applies-theme-styling**: Component MUST set the text field's font to the
  theme's body-role font and its text color to the theme's primary-text
  color, both immediately upon construction and again on every subsequent
  theme change.
- **restyles-existing-placeholder**: Component MUST, whenever a theme
  change fires and the field's placeholder text is set at that moment,
  restyle the placeholder in the theme's body-role font and
  placeholder-text color.
- **exposes-constituent-views**: Component MUST expose its label and its
  text field as public, directly-accessible, immutable sub-components.
- **claims-sole-onchange-observer**: Component MUST assign its own handler
  to the view model's change notification during initialization,
  superseding any handler already registered on that view model instance
  (see **overwritten external observer** in Edge Cases).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

