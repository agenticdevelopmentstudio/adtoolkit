
- Role/trait: Not applicable at this component's level. The component
  never marks itself as an accessibility element or overrides any
  accessibility role; it is a plain layout container, and assistive
  technology traverses directly into each row's own accessibility
  elements.
- Label requirements: Not applicable. The component creates no accessible
  label of its own; every row's title, description, and status text carry
  their own labeling, as does that row's action button.
- Announce state changes: Not applicable at this component's level. The
  component issues no accessibility notification of its own when a
  refresh completes; a status change is reflected as an ordinary
  text/color update inside the affected row, which is that row
  component's concern.
- Minimum tap target: Not applicable. The component has no tappable
  surface of its own — the tap targets are each row's action button,
  sized by the row component.
- Keyboard navigation: Not applicable. The component sets no custom
  key-view loop, first responder, or key-equivalent; whatever tab order
  the platform derives automatically from the arranged-subview hierarchy
  applies unmodified.

- Grouping: The component calls no accessibility-grouping operation of its
  own on itself, so assistive technology gets no grouping cue for the row
  list beyond the plain view hierarchy and traverses straight into each
  row's own accessibility elements.

