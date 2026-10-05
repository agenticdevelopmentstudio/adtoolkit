
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **arranges-children-horizontally**: The component MUST arrange its
  children in a horizontal row.
- **group-spacing**: The component MUST set the spacing between arranged
  children to the standard group-spacing value (20.0pt) at initialization.
- **adds-stack-view-as-subview**: The internal stack view MUST be a child
  of the component itself (see Platform Notes for how the source wires
  this).
- **pins-stack-view-to-container-edges**: The component MUST activate
  constraints pinning the internal stack view's top, leading, trailing,
  and bottom edges to the component's corresponding edges (see Platform
  Notes for the helper the source uses).
- **rejects-deserializing-construction**: A deserializing/decoding-based
  construction path MUST NOT produce a usable instance; it MUST trap or
  fail instead (see Platform Notes for the source's trap message).
- **forwards-added-views-to-inner-stack-view**: The component's public
  add-view operation MUST forward its argument to the internal stack view
  (see Platform Notes for the call the source uses).

