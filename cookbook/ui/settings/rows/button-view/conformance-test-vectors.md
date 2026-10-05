
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| button-view-001 | creates-button-with-view-model-title | Construct with a view model whose title is "Save" | The button's title is "Save" |
| button-view-002 | creates-button-with-view-model-title | Construct with a view model whose title is empty | The button's title is empty; no crash |
| button-view-003 | exposes-button-publicly | Any initialized instance | The button is externally accessible, is the same instance the component displays, and is fully contained within the component's layout (not a detached or independently-positioned element; see Platform Notes for the mechanism the source uses) |
| button-view-006 | defaults-placement-to-fill | Construct with no explicit placement | Resulting layout matches the fill behavior in button-view-007 |
| button-view-007 | fills-view-in-fill-placement | Placement is fill, host component laid out at 200×40 | The button's frame equals (0, 0, 200, 40) |
| button-view-008 | constrains-vertical-edges-in-non-fill-placement | Placement is leading, host component laid out at 200×40 | The button's top and bottom edges equal the host's top and bottom edges (button height == 40) |
| button-view-009 | caps-trailing-edge-in-non-fill-placement | Placement is leading, the title's intrinsic width exceeds the host's width | The button's trailing edge does not exceed the host's trailing edge |
| button-view-010 | aligns-leading-edge-in-leading-placement | Placement is leading | The button's leading edge equals the host's leading edge |
| button-view-011 | floors-leading-edge-in-centered-placement | Placement is centered, host wider than the button's intrinsic width | The button's leading edge is greater than or equal to the host's leading edge |
| button-view-012 | centers-button-in-centered-placement | Placement is centered, host component laid out at 200×40 | The button's horizontal center equals the host's horizontal center (x == 100) |
| button-view-013 | wires-button-action | Any initialized instance | The button's press interaction is wired to the component's own press-handling logic, not a callback attached directly on the button (verified as an implementation/code-inspection check; see Platform Notes for the mechanism the source uses) |
| button-view-014 | invokes-pressed-callback | The view model's `wasPressedCallback` set to a callback that flips a flag; simulate a press on the button | The flag is true after the press |
| button-view-015 | takes-no-action-without-callback | The view model's `wasPressedCallback` unset; simulate a press on the button | No exception is thrown; no call is observed on a spy substituted for any other collaborator |
| button-view-016 | requires-view-model-at-construction | Attempt to construct via a bare/default construction path that supplies no view model | Construction is rejected; no usable instance is produced. Not testable as an ordinary in-process assertion on every platform — where the failure mode is a runtime trap rather than a thrown/returned error, this requires a crash-test harness or a compile-time/unavailable check instead. |
| button-view-017 | requires-view-model-at-construction | Attempt to construct via a serialization/decoding-based construction path that supplies no view model | Construction is rejected; no usable instance is produced. Same testing caveat as above. |
| button-view-018 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |
| button-view-019 | placement-fixed-at-init | Any initialized instance | The component's public interface exposes no property or method that reads or changes placement; the only code that consults placement runs once, during construction |
| button-view-020 | reads-title-once-at-init | Any initialized instance | The button's title was set from the view model's title during construction and by no other code path; the view model's title is immutable, so no later value could exist for the component to re-read |
| button-view-021 | retains-view-model-strongly | Construct the component with a view model carrying a press callback that flips a flag, in a scope where no other strong reference to the view model is kept; after the scope exits (only the component remains reachable), simulate a press on the button | The callback still fires and the flag becomes true, showing the component alone kept the view model (and its callback) alive after every other reference was dropped |

`button-view-013`, `button-view-018` and `button-view-019` are static,
code-inspection checks (the platform's press-wiring mechanism and UI-thread
isolation checking reject a violation at compile time or by construction;
placement having no
reachable getter/setter is a fact about the type's public interface), not
vectors observed by running the program; a port on a platform without the
equivalent compile-time enforcement should verify these as build-verification
or API-surface review notes rather than runtime tests.

