
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| horizontal-stack-view-001 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged. This is a static/compile-time check on such platforms, not one a runtime conformance suite executes. |
| horizontal-stack-view-003 | arranges-children-horizontally | Inspect the internal stack view of any initialized component | Its orientation is horizontal |
| horizontal-stack-view-004 | group-spacing | Inspect the internal stack view of any initialized component | Its spacing equals the standard group-spacing value (20.0pt) |
| horizontal-stack-view-006 | adds-stack-view-as-subview | Any initialized component | The internal stack view is the component's only child |
| horizontal-stack-view-007 | pins-stack-view-to-container-edges | Inspect the internal stack view of any initialized component, laid out in a container with a non-zero frame | The stack view's resolved bounds exactly match the component's bounds (top/leading/trailing/bottom edges resolve equal) |
| horizontal-stack-view-010 | rejects-deserializing-construction | Attempt to construct the component via a deserializing/decoding-based construction path | Construction traps or fails; no usable instance is produced (any trap message satisfies the requirement; the source's is `init(coder:) has not been implemented`, see Platform Notes) |
| horizontal-stack-view-011 | forwards-added-views-to-inner-stack-view | Construct the component, obtain its internal stack view, then add a child view through the component's public add-view operation | The child view appears among the internal stack view's arranged children, in the order it was added |

Three implementation-only construction-rule checks (disabling autoresizing-
mask translation on the component and its internal stack view, discarding
an explicit frame at construction, and the parameterless constructor's
use of a zero frame) and the platform's marker-interface conformance are
framework mechanics rather than portable behavior; see Platform Notes for how the source verifies them there.

