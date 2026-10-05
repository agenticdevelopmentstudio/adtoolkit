
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dismissible-hint-view-001 | text-label | Construct the component with hint text `"Enable launch at login"` | The hint label's content equals `"Enable launch at login"`; the label wraps rather than truncates |
| dismissible-hint-view-002 | #platforms/swift | Construct the component, then read its hint-label property from outside the type | Returns the same view instance the component uses for its hint label |
| dismissible-hint-view-003 | text-label-theming | Construct the component, then trigger a theme change | The hint label's color and font update to the new theme's secondary-text color and caption font, both immediately at construction and again after the change |
| dismissible-hint-view-004 | dismiss-button-title | Construct the component with an explicit button title of `"Dismiss"` | The dismiss button's title equals `"Dismiss"` |
| dismissible-hint-view-005 | dismiss-button-title-default | Construct the component with no button title supplied | The dismiss button's title equals `"Got It"` |
| dismissible-hint-view-006 | #platforms/swift | Construct the component, then read its dismiss-button property from outside the type | Returns the same view instance the component uses for its dismiss button |
| dismissible-hint-view-007 | dismiss-button-style | Construct the component | The dismiss button renders in the component's small, rounded button style |
| dismissible-hint-view-008 | dismiss-button-action | Construct the component, then simulate a click on the dismiss button | The dismiss handling runs (verified by dismiss-persistence's effect) |
| dismissible-hint-view-009 | stack-arrangement | Construct the component | The internal stack is vertical, leading-aligned, with the hint label before the dismiss button |
| dismissible-hint-view-010 | stack-spacing | Construct the component | The internal stack's spacing equals the standard row spacing (8pt) |
| dismissible-hint-view-011 | #platforms/swift | Construct the component | Active layout constraints pin the stack's top/leading/trailing/bottom edges to the component's corresponding edges, each with a zero offset |
| dismissible-hint-view-012 | #platforms/swift | Construct the component | The component and its internal stack both opt out of any implicit frame-based sizing |
| dismissible-hint-view-013 | dismissed-setting-observation | Construct with a given dismissed-setting | The component's internal observer wraps that exact setting instance |
| dismissible-hint-view-014 | initial-visibility | Construct with the dismissed-setting's current value equal to `true` | Immediately after construction, the component is hidden, with no visibility-change callback invoked |
| dismissible-hint-view-015 | initial-visibility | Construct with the dismissed-setting's current value equal to `false` | Immediately after construction, the component is shown |
| dismissible-hint-view-016 | visibility-update | After construction while shown, change the setting's value to `true` and allow the change to deliver | The component becomes hidden after delivery |
| dismissible-hint-view-017 | visibility-write-guard | With the component hidden, cause the observed value to redeliver `true` again | The component's shown/hidden state is not reassigned for this delivery, and the visibility-change callback's call count stays at zero |
| dismissible-hint-view-018 | visibility-change-notification | Register the visibility-change callback, then change the setting from `false` to `true` | The callback is called exactly once, after the component has already become hidden |
| dismissible-hint-view-019 | visibility-change-callback | Assign a callback to the visibility-change property from outside the type, then trigger a visibility change | The assigned callback is the one invoked |
| dismissible-hint-view-020 | dismiss-persistence | Click the dismiss button | The dismissed-setting's persisted value becomes `true` |
| dismissible-hint-view-021 | self-hiding-conformance | Construct the component | The component exposes a visibility-change callback and identifies itself to a hosting container as capable of self-hiding |
| dismissible-hint-view-022 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

Vector `dismissible-hint-view-021` is a static/type-check vector (verifying
the component identifies itself to hosting containers as self-hiding), not
a runtime behavior assertion.

