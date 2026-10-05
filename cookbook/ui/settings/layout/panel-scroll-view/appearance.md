
- **Corner radius**: Not applicable — the component draws no background
  or border chrome of its own, so no corner radius applies.
- **Padding**: 0pt on all edges — every constraint in source (document to
  viewport at construction, and installed content to the document view in
  the set-content operation) omits an explicit constant, which defaults
  to 0.
- **Font**: Not applicable — the component renders no text of its own;
  any typography belongs to the content installed via the set-content
  operation.
- **Background**: Transparent — the scroll view paints no background of
  its own, so whatever sits behind it shows through.
- **Foreground/Text**: Not applicable — the same reasoning as Font; the
  component has no text or tint of its own to color.
- **Border**: Not applicable — no border color, width, or style is
  configured anywhere in the source; the view relies on the platform's
  inherited default and draws no background of its own.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in the source.
- **Min/Max size**: Not applicable — the component itself sets no minimum
  or maximum size constraint; only the *installed content's* height is
  constrained to be at least the viewport height (see
  **content-min-height-viewport**).

