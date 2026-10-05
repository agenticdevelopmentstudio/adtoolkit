
- **Corner radius**: Not set by this component. Rows are plain row views
  with no corner radius anywhere in the ancestor topic list component's
  cell factories, and this component overrides none of that layout.
- **Padding**: Not set by this component; inherited unmodified from the
  ancestor's own layout metrics — see
  `adtoolkit://cookbook/ui/navigation/topic-list#appearance`
  for the insets this component renders with.
- **Font**: Not set by this component; inherited unmodified from the same
  layout metrics — see
  `adtoolkit://cookbook/ui/navigation/topic-list#appearance`.
- **Background**: Not set by this component; inherited unmodified — the
  ancestor's theme-application step paints the view, content stack,
  header, footer, and list/scroll background. See
  `adtoolkit://cookbook/ui/navigation/topic-list#appearance`.
- **Foreground/Text**: Not set by this component; inherited unmodified
  from the ancestor's row-rendering step. See
  `adtoolkit://cookbook/ui/navigation/topic-list#appearance`
  for the exact color/state mapping this component's rows use.
- **Border**: Not set by this component. The ancestor draws a 1pt hairline
  divider above every row in a card except the first, but a plain sidebar
  row (as this component uses) draws no such divider; no border is set
  anywhere in either component.
- **Shadow**: Not applicable — no shadow or layer-shadow property is set
  anywhere in this component or its ancestor.
- **Min/Max size**: Not set by this component. The ancestor computes the
  sidebar's content-driven width from the widest row/title, and this
  component does not override it; there is no maximum width in either
  component.

