
**Decision**: Override the detail-pane minimum-thickness floor to `200`
points rather than inheriting the settings split view's `400`pt default.
**Rationale**: "A modest floor so the nested detail (the sub-panel
content) can't be squeezed to a sliver. It stays below the outer detail's
own floor, so it caps the inner content rather than compounding the
window's minimum width."
**Approved**: pending

**Decision**: Override the content-sized-sidebar flag to true rather than
inheriting the settings split view's draggable, autosaved default.
**Rationale**: "Nested topic lists are content-sized and unified to one
width by the parent split, so switching between sibling panels never
shifts the inner divider and every title stays fully disclosed."
**Approved**: pending

**Decision**: Redeclare help content, effective help content, and search
keywords on this class rather than relying solely on the shared
protocol-extension defaults. (AppKit.)
**Rationale**: A protocol extension's default is bound at the point of
conformance; a subclass override reachable only through the extension
default would be invisible through the generic interface the enclosing
split holds. Redeclaring the properties on the class keeps subclass
overrides reachable.
**Approved**: pending

