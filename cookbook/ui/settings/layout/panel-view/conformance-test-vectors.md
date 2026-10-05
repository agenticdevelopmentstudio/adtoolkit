
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-view-002 | confines-to-ui-thread | (Static/compile-time check) Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (compile-time on platforms with static isolation checking, runtime-checked otherwise) |
| panel-view-004 | see Design Decisions | Construct the component with an explicit non-zero frame, checked immediately after construction, before layout | The resulting view's frame is zero, not the supplied rect |
| panel-view-007 | vertical-leading-stack-alignment | Construct the component | The internal stack's orientation is vertical and its alignment is leading |
| panel-view-008 | group-spacing | Construct the component | The internal stack's spacing equals 20.0 |
| panel-view-010 | top-leading-trailing-inset | Construct the component | Active constraints pin the stack's top/leading/trailing edges to the view's corresponding edges, each with constant 20.0 inward |
| panel-view-011 | bottom-inset-inequality | Inspect the component's active constraints | An inequality constraint relates the stack's bottom edge to the view's bottom edge with constant −20.0; no equality constraint exists between them |
| panel-view-012 | construction-time-background-paint | Construct the component under a known theme | The background equals that theme's window-background color immediately after construction returns |
| panel-view-013 | theme-change-background-repaint | Construct the component, then switch the active theme | The background updates to the new theme's window-background color |
| panel-view-015 | rejects-deserializing-construction | Attempt to construct the component via a deserializing/decoding-based construction path | Execution traps or fails; the exact message text is not required by this requirement (see Design Decisions) |
| panel-view-016 | group-arranged-subview-append | Call the add-group operation with a group view | The group view is an arranged child of the internal stack, at the end |
| panel-view-017 | heading-construction | Call the add-heading operation with title "Section" and caption "Some blurb" | A panel heading view is constructed with those two values forwarded to it (see the Panel Heading View recipe for how these values render) |
| panel-view-018 | heading-caption-default | Call the add-heading operation with title "Section" and no caption argument | The constructed panel heading view receives an absent caption (see the Panel Heading View recipe for its own no-caption behavior) |
| panel-view-019 | heading-gap | Call the add-group operation with a group view, then the add-heading operation with title "Section" | The stack's custom spacing after that group view is 30.0 |
| panel-view-020 | empty-stack-spacing-skip | Call the add-heading operation with title "Section" as the first call on a freshly constructed component | No custom spacing is set (the stack has no prior arranged child); no crash occurs |
| panel-view-021 | heading-arranged-subview-append | Call the add-heading operation with title "Section" | The returned panel heading view is an arranged child of the internal stack, at the end |
| panel-view-022 | heading-width-match | Call the add-heading operation with title "Section" | An active constraint equates the returned heading's width to the internal stack's width |
| panel-view-023 | heading-return | Capture the return value of the add-heading operation called with title "Section" | The returned value is the same panel heading view instance added to the stack; the caller can ignore the return value with no compiler warning |

Three implementation-only construction-rule checks (a parameterless
construction path forwarding to a zero frame, disabling the legacy
autoresizing-mask/frame system on the component and its internal stack,
and making the component layer-backed so a background color can be
painted) and one memory-management-only check (retaining the internal
theme-change observer for the view's lifetime) are framework mechanics
rather than portable behavior; see Platform Notes for
how the source implements them. Likewise, the marker-protocol conformance
this component satisfies is covered there rather than as a normative
requirement.

