
- **Corner radius**: Not applicable — the component sets no custom layer
  or corner radius of its own; any rounded corners belong to the composed
  choice control (uncornered, per its own recipe) or the preview's own
  internal cards, which are a separate concept.
- **Padding**: The stack's 10pt spacing is the only gap the component
  itself introduces, between the choice control and the preview. The
  stack's edges are pinned to the component's own edges with no additional
  constant, so the component contributes 0pt of outer padding beyond that
  internal 10pt gap.
- **Font**: Not applicable — no font is set by this component; the choice
  control's label font and every sample font drawn inside the preview are
  each owned by their own concept.
- **Background**: None — the component sets no background color or layer
  of its own.
- **Foreground/Text**: Not applicable — the component draws no text of
  its own; all visible text belongs to the composed choice control and
  preview.
- **Border**: None — no border is drawn or configured by this component.
- **Shadow**: Not applicable — no shadow is drawn or configured by this
  component.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set by this component; sizing comes entirely from the
  choice control's and preview's own intrinsic/explicit sizing (the
  preview's own cards enforce a minimum width of 280pt, reasserted for the
  terminal card) composed inside the vertical stack.

