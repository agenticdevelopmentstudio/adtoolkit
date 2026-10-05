
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **vertical-leading-stack-alignment**: The component MUST construct an
  internal vertical stack with leading alignment.
- **group-spacing**: The component MUST set the internal stack's spacing
  to the standard group-spacing value (20pt).
- **top-leading-trailing-inset**: The component MUST pin the internal
  stack's top, leading, and trailing edges to its own corresponding edges,
  each offset by the standard panel-inset value (20pt) inward.
- **bottom-inset-inequality**: The component MUST constrain the internal
  stack's bottom edge to be no further than the standard panel-inset value
  (20pt) from its own bottom edge — an inequality, not an equality
  constraint.
- **construction-time-background-paint**: The component MUST set its
  background to the current theme's window-background role, resolved for
  the component's own theme scope, immediately at construction.
- **theme-change-background-repaint**: The component MUST update its
  background to the new theme's window-background role every time the
  active theme changes or the component's resolved theme scope changes,
  for the lifetime of the view.
- **rejects-deserializing-construction**: A deserializing/decoding-based
  construction path MUST trap or fail when invoked; the exact trap message
  is not part of this requirement (see Design Decisions).
- **group-arranged-subview-append**: The add-group operation MUST add the
  given group view as the next arranged child of the internal stack, with
  no other transformation.
- **heading-construction**: The add-heading operation MUST construct a
  panel heading view from its own title and caption parameters.
- **heading-caption-default**: The add-heading operation MUST default its
  caption parameter to absent when the caller omits it.
- **heading-gap**: When the internal stack already has at least one
  arranged child at the time the add-heading operation is called, the
  component MUST set the custom spacing after that existing last arranged
  child to 1.5x the standard group-spacing value (30pt), before adding the
  new heading.
- **empty-stack-spacing-skip**: When the internal stack has no arranged
  children at the time the add-heading operation is called, the component
  MUST NOT attempt to set any custom spacing (there is no prior arranged
  child to set it after).
- **heading-arranged-subview-append**: The add-heading operation MUST add
  the constructed panel heading view as the next arranged child of the
  internal stack, after any spacing adjustment above has been made.
- **heading-width-match**: The add-heading operation MUST activate a
  constraint equating the constructed heading's width to the internal
  stack's width.
- **heading-return**: The add-heading operation MUST return the
  constructed panel heading view to its caller.

