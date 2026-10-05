
- **Role/trait**: Not set explicitly anywhere in this component. The
  search field, the table, and the row checkbox each carry the platform's
  own default accessibility role for their control type; the
  title/description/detail/separator labels are plain text labels, which
  the platform exposes as static text by default.
- **Label requirements**: The search field's placeholder text supplies its
  own accessible hint through the platform's stock search-field behavior.
  The multi-select checkbox is built with an empty title of its own, and
  this component never links it to the row's own title label through an
  accessibility-label or title-linking API — so a screen reader announces
  the checkbox by its generic checkbox role only, with no descriptive
  label tying it to the row it belongs to.
- **Announce state changes (e.g., loading, disabled)**: Highlight changes
  move the native table selection, which is the platform's own stock
  accessibility behavior for a real, undisguised table; nothing in this
  component suppresses or replaces that default notification. There is no
  loading or disabled state to announce (see States).
- **Minimum tap target**: Not applicable — this is a
  pointer/trackpad-driven composition with no touch input path anywhere in
  source; the fixed 24pt row height sizes rows for pointer hit-testing on
  this platform, not against a touch-target guideline.

