
- **Corner radius**: Not applicable — this component draws no chrome of
  its own; any corner radius shown by hosted content belongs to that
  content's own recipe (e.g. a group view's card).
- **Padding**: Not applicable — no padding or inset constant is set in
  this component; the inherited settings split view owns the sidebar/
  detail layout this component does not override.
- **Font**: Not applicable — this component draws no text of its own.
- **Background**: Not applicable — no background is set in this
  component; the inherited settings split view's theme-application step
  paints the window/detail background, and this component does not
  override it.
- **Foreground/Text**: Not applicable — this component sets no color.
- **Border**: Not applicable — no border is configured in this component.
- **Shadow**: Not applicable — no shadow is configured in this component.
- **Min/Max size**: The detail-pane minimum-thickness floor is overridden
  to `200` points — a floor on the nested detail pane's width, not a
  maximum; no maximum size is set anywhere in this component. This floor
  deliberately stays below the inherited settings split view's default
  floor of `400` points, so it caps only the inner content rather than
  compounding the window's overall minimum width.

