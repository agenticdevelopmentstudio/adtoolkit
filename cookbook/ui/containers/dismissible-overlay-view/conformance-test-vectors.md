
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dismissible-overlay-004 | blurred-backdrop | Inspect the backdrop after construction | A blurred backdrop subview exists, using a within-window blending behavior and kept in its active appearance state |
| dismissible-overlay-005 | backdrop-subview-order | Construct a subclass that adds one content subview after calling the base initializer | The first (bottommost) subview is the backdrop; the content subview appears after it |
| dismissible-overlay-006 | backdrop-material-default | Constructed with no `material` argument | The backdrop uses the platform's default material |
| dismissible-overlay-007 | backdrop-material-override | Constructed with a caller-supplied `material` value | The backdrop uses that caller-supplied material value |
| dismissible-overlay-008 | host-coverage | Present the overlay in a host view | Overlay is a subview of the host, with top/leading/trailing/bottom anchors each constrained equal to the matching host anchor |
| dismissible-overlay-009 | present-layout-order | Present the overlay in a host, then synchronously (before the next run-loop turn) inspect the host's subview layout and the overlay's frame | The host's subtree is already laid out and the overlay's frame already reflects its final host-pinned size at the moment presentation returns, before any animation frame renders |
| dismissible-overlay-010 | present-fade | Present the overlay in a host, inspecting the fade animation's duration from an injected/overridden animation hook | The fade animation's duration `== fadeDuration` (0.2s) while it runs; opacity reaches `1` once the animation completes |
| dismissible-overlay-011 | dismiss-fade | Dismiss a fully presented overlay, inspecting the fade animation's duration from the same injected/overridden animation hook | The fade animation's duration `== fadeDuration` (0.2s) while it runs; opacity reaches `0` once the completion handler runs |
| dismissible-overlay-012 | post-fade-removal | Dismiss the overlay and wait for the fade-out animation to complete | The overlay's superview becomes absent once the completion handler runs |
| dismissible-overlay-013 | dismiss-idempotency | Dismiss the overlay twice in immediate succession | The pre-dismissal hook and `onDismissed` are each invoked exactly once; exactly one fade-out animation runs |
| dismissible-overlay-014 | dismissing-flag-timing | Dismiss the overlay; read `isDismissing` synchronously, before the animation completes | `isDismissing == true` immediately |
| dismissible-overlay-015 | will-dismiss-timing | Override the pre-dismissal hook to record a timestamp, then dismiss the overlay | The recorded timestamp precedes any change to opacity |
| dismissible-overlay-016 | dismissed-callback-timing | Set `onDismissed` to record a timestamp, then dismiss the overlay | The recorded timestamp precedes the fade-out animation's completion handler |
| dismissible-overlay-017 | default-will-dismiss | Dismiss a plain (non-subclassed) instance | No observable side effect beyond the fade-out and removal; no crash |
| dismissible-overlay-018 | mouse-down-dismissal | Deliver an unclaimed press directly to the overlay | The overlay dismisses itself |
| dismissible-overlay-019 | key-equivalent-subview-priority | Add a subview whose own key-equivalent handling reports Return as handled, then send a Return key event | The event is reported as handled; the overlay does NOT dismiss itself |
| dismissible-overlay-020 | escape-return-dismissal | Send an Escape key event, unclaimed by any subview | The event is reported as handled; the overlay dismisses itself |
| dismissible-overlay-020b | escape-return-dismissal | Same as above, with a Return key event | Same as above |
| dismissible-overlay-020c | escape-return-dismissal | Same as above, with a keypad Enter key event | Same as above |
| dismissible-overlay-021 | non-dismiss-key-equivalents | Send a Space key event, unclaimed by any subview | The event is reported as unhandled; the overlay does NOT dismiss itself |
| dismissible-overlay-022 | key-equivalents-during-dismissal | Dismiss the overlay, then immediately send an Escape key event before the fade-out completes | The event is reported as unhandled; the overlay is not dismissed a second time |
| dismissible-overlay-023 | open-subclassing | Define a subclass overriding presentation, the pre-dismissal hook, and the press- and key-equivalent-handling entry points | Code compiles; the subclass's overrides run in place of the base implementation |
| dismissible-overlay-024 | optional-dismissed-callback | Leave `onDismissed` as `nil`, then dismiss the overlay | No crash; the fade-out animation and removal from superview still proceed |
| dismissible-overlay-025 | key-equivalent-subview-priority | Present one overlay in a host, then present a second instance as a subview added above the first (mirroring "a message expanded over a conversation"); send an Escape key event | The outer (first-presented) overlay's key-equivalent handling reports the event as handled via reaching the inner overlay first; only the inner (topmost) overlay dismisses itself, not the outer one |
| dismissible-overlay-026 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

`will-dismiss-cleanup` has no test vector: it is guidance for
what a subclass author puts inside their own override, not a behavior
the component itself performs or can verify at the component
level (see Design Decisions).

