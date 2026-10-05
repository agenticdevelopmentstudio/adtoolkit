
- **Role/trait**: The source never sets an explicit accessibility role on
  the title label; the platform exposes it, as a non-editable text field,
  as ordinary static text, not as a heading. The component's stated
  purpose (per its own doc comment) is to caption a *run* of groups the
  way a section heading would, but the source establishes that
  relationship only visually (size and weight): it sets no accessibility
  heading role/trait on the title label, so screen-reader users have no
  way to jump between panel headings the way heading navigation would let
  them.
- **Label requirements**: Satisfied for the title — the title label's
  displayed text is always the exact, caller-supplied title argument
  (**sets-title-text-from-caller**), which is also its accessible name
  under the platform's default behavior for this kind of text field. The
  caption's own label requirements are covered by the Explanation View
  recipe, not duplicated here — this component only forwards that view's
  label as its own caption-label accessor.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the component defines no loading or disabled state to announce (see
  States). Whether a caption exists is fixed at construction, not a
  runtime state change this component makes after the fact.
- **Minimum tap target**: Not applicable — the source defines no
  target/action, gesture recognizer, or click handling; this is a purely
  visual, non-interactive display element with no tap target to size.

