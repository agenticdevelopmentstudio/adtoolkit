
- **Role/trait**: Not applicable — this component sets no accessibility
  role of its own; it is a plain container, and any role for rendered UI
  belongs to the inherited sidebar/detail views, each covered by its own
  recipe.
- **Keyboard/assistive technology navigation**: Not applicable in this
  component — no keyboard handling is added or overridden here; the
  inherited settings split view's search-field arrow-key handling and
  standard split-view tab order are unmodified by this component.
- **Label requirements**: Not applicable to this component — the sidebar
  title is set from the caller-supplied descriptor's title, but rendering
  that title (and whatever accessible label it produces) is the panel
  list's responsibility, a separate component with its own recipe; this
  component assigns no accessibility label of its own.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  this component has no loading or disabled state to announce (see
  States).
- **Minimum tap target**: Not applicable — this component defines no
  interactive control of its own.

