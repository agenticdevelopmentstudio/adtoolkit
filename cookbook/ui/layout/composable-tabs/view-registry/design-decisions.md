
- **Decision**: The view registry is an instance, obtained per project
  through its composable-tabs layout, not a global singleton or namespace
  of statics.
  **Rationale**: Per the source's own comment, the demo project and a real
  app project need different view sets in the same process, and with global
  registration the last registrant wins.
  **Approved**: pending
- **Decision**: The `placeholder` view id can never be unregistered.
  **Rationale**: Per the source's own comment, every registry must always be
  able to resolve `placeholder`, because losing it would lose the layout
  built on it — a project's stored layout can name `placeholder` explicitly.
  **Approved**: pending
- **Decision**: An unregistered view id resolves to a placeholder rather than
  throwing or trapping, but is still logged at error level.
  **Rationale**: The source's own comment: a project can legitimately name
  content the running app doesn't have (an uninstalled extension), so a hard
  failure would be wrong, but the same situation can also mean spec/registry
  drift, which the source treats as something that should stay visible rather
  than silently rendering "Pane N" with no trace.
  **Approved**: pending
- **Decision**: A factory vends a view controller, never a bare view.
  (AppKit/UIKit.)
  **Rationale**: Per the source's own comment, the pane view controller
  adopts the returned controller as a child, which is what puts the content
  in the responder chain, delivers its appearance callbacks, and keeps it
  alive; a bare view would leave its owner unowned and its appearance
  callback silent.
  **Approved**: pending
- **Decision**: The tree id defaults to the node id when the caller passes
  none, rather than generating a shared default or leaving it unset.
  **Rationale**: Per the source's own comment, a pane with no tree above it
  is its own tree, so its identity degrades to "pairs with nothing" instead
  of "pairs with a shared default every such lone pane would collide on."
  **Approved**: pending
- **Decision**: The context is a value type with a state-store-construction
  method, rather than each factory constructing its own state store.
  **Rationale**: Per the source's own comment, this keeps where a nested
  pane's rows live to one decision in one place, instead of a key every
  factory has to spell the same way.
  **Approved**: pending
- **Decision**: The placeholder pane draws its primary-text title over a 15% chart-series tint with no contrast check.
  **Rationale**: The token values are chosen per theme outside this component, so the pairing cannot be computed here; closing the gap means auditing each shipped theme's chart-series and primary-text tokens against 4.5:1.
  **Approved**: pending

