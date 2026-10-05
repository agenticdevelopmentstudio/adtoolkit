
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **arranges-children-vertically**: The component MUST construct an
  internal stack oriented vertically.
- **sets-arranged-subview-spacing-from-group-spacing-token**: The
  component MUST set the internal stack's spacing to the standard
  group-spacing value (20.0pt) at construction.
- **adds-stack-view-as-subview**: The component MUST add the internal
  stack view to itself as a child view.
- **pins-stack-view-to-container-edges**: The component MUST activate
  constraints pinning the internal stack view's top, leading, trailing,
  and bottom edges to the corresponding edges of the component itself.
- **exposes-stack-view-as-public-property**: The component MUST expose
  its internal stack view as a public, read-only property.
- **rejects-deserializing-construction**: A deserializing/decoding-based
  construction path MUST fail with the message `init(coder:) has not been
  implemented`.
- **forwards-added-views-to-inner-stack-view**: The add-arranged-view
  operation MUST forward its argument to the internal stack view.

