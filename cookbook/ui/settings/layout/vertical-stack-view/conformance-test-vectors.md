
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vertical-stack-view-001 | confines-to-ui-thread | (Static/compile-time check) Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (compile-time on platforms with static isolation checking, runtime-checked otherwise) |
| vertical-stack-view-003 | arranges-children-vertically | Any initialized component | The internal stack's orientation is vertical |
| vertical-stack-view-004 | sets-arranged-subview-spacing-from-group-spacing-token | Any initialized component | The internal stack's spacing equals the standard group-spacing value |
| vertical-stack-view-006 | adds-stack-view-as-subview | Any initialized component | The internal stack view is present among the component's child views |
| vertical-stack-view-007 | pins-stack-view-to-container-edges | Any initialized component, laid out in a window with a non-zero frame | Active constraints link the internal stack view's top/leading/trailing/bottom edges to the corresponding edges of the component, and (after layout) the internal stack view's frame exactly matches the component's bounds |
| vertical-stack-view-008 | exposes-stack-view-as-public-property | From outside the type, read the exposed stack-view property | The property is accessible, and returns the same internal stack-view instance the add-arranged-view operation forwards to |
| vertical-stack-view-009 | see Design Decisions | Construct via the frame-accepting initializer with an explicit non-zero frame | The resulting view's frame is zero, immediately after construction, before any layout pass runs |
| vertical-stack-view-011 | rejects-deserializing-construction | Attempt to construct the component via a deserializing/decoding-based construction path | Execution fails with the message `init(coder:) has not been implemented` |
| vertical-stack-view-012 | forwards-added-views-to-inner-stack-view | Construct the component, then call the add-arranged-view operation with a child view | The child view appears among the internal stack view's arranged children, in the order it was added |

Three implementation-only construction-rule checks (disabling the legacy
autoresizing-mask/frame system on the component and on its internal stack,
and a parameterless construction path that forwards to a zero frame) and
one marker-role conformance check are framework mechanics rather than
portable behavior; see Platform Notes for how the
source implements them.

