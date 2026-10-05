
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wpvc-001 | panel-id-generated-at-init | Construct two panels with identical arguments | Their identifiers are non-empty strings and differ from each other |
| wpvc-002 | init-applies-scheme-handler-and-relay | Construct a panel with a known set of resource roots and options | Immediately after construction, the scheme handler's resource roots and Content-Security-Policy match the given values, before the view is ever constructed |
| wpvc-003 | restoring-init-seeds-prior-state | Construct from a stored panel state with `viewType: "v"`, `title: "T"`, `state: "{\"a\":1}"`, and a known `options` value, plus a known set of resource roots | `viewType == "v"`, `title == "T"`, `state == "{\"a\":1}"`, `options` equals the given value |
| wpvc-005 | thread-confined-access | Attempt, from outside the confined execution context, to call a method or read a property of the component, the message relay, or the navigation-policy role | The access is rejected before it can occur, confirming every declaration requires the confined execution context (enforcement mechanism: see Platform Notes) |
| wpvc-006 | title-change-notifies-listeners | Install spies on both callbacks, set `title` from `"Old"` to `"New"` | Both spies fire exactly once, in order |
| wpvc-007 | title-unchanged-suppresses-notification | With `title == "Same"`, set `title = "Same"` again | Neither spy fires |
| wpvc-008 | html-change-reloads-document | After constructing the view, assign a new `html` value | The host document reloads |
| wpvc-009 | html-unchanged-suppresses-reload | After constructing the view, assign `html` its current value | No reload occurs |
| wpvc-010 | constructing-the-view-configures-the-sandbox | Construct the view with `options.enableScripts == false` | The scheme handler is registered for `agentic-webview`, the message relay is the `agenticWebview` message handler, script execution is disabled, and the data store is non-persistent |
| wpvc-011 | constructing-the-view-disables-back-forward-gestures | Construct the view | The webview's back/forward navigation gestures are disabled |
| wpvc-012 | constructing-the-view-tracks-theme-surface-color | Construct the view under theme A, read the background color, then switch to theme B | The color equals theme A's surface color after construction and theme B's after the switch, with no further action |
| wpvc-013 | constructing-the-view-loads-host-document | Construct the view | The webview's loaded request URL equals the panel's host-document URL |
| wpvc-014 | load-host-document-noop-after-disposal | Dispose the panel, then assign a new `html` value | No further load reaches the webview |
| wpvc-015 | load-host-document-wraps-extension-html | Set `html` and `state` to known values around constructing the view | The scheme handler's document equals the wrapped form of that `html` and `state` |
| wpvc-016 | local-resource-roots-proxy-to-scheme-handler | Set the panel's resource roots to `[dirA, dirB]` | Reading the panel's resource roots and the scheme handler's own roots both return `[dirA, dirB]` |
| wpvc-017 | options-change-updates-content-security-policy | Change `options.enableForms` from `false` to `true` | The scheme handler's Content-Security-Policy no longer contains `form-action 'none'` |
| wpvc-018 | options-change-notifies-restoration-listeners | Install a spy, assign a different `options` value | The spy fires exactly once |
| wpvc-019 | options-change-reloads-loaded-document | After constructing the view, assign a different `options` value | The host document reloads |
| wpvc-020 | options-unchanged-suppresses-all-effects | Assign `options` a value equal to the current one | No CSP change, no callback, no reload occurs |
| wpvc-021 | post-rejects-unbridgeable-values | After constructing the view, post a message with an unbridgeable value (e.g. a raw URL object) | Returns `false`; no script is dispatched; the failure is logged as an error |
| wpvc-022 | post-returns-false-when-unavailable | Post a message before the view is constructed, and again after disposing the panel | Both calls return `false` |
| wpvc-023 | post-dispatches-message-event | After constructing the view, post a message with a value such as `{"a": 1}` | Returns `true`; the value is dispatched as a `message` event's `data` |
| wpvc-024 | postable-scalar-types-accepted | Check postability of a null value, a number, a string, and a date | All four are accepted |
| wpvc-025 | postable-dictionary-requires-string-keys | Check postability of a string-keyed dictionary and of a number-keyed dictionary | First accepted, second rejected |
| wpvc-026 | postable-array-recurses | Check postability of an array containing one non-postable element | Rejected |
| wpvc-027 | received-message-ignored-after-disposal | Dispose the panel, then deliver a page message | `onDidReceiveMessage` does not fire |
| wpvc-028 | post-message-forwarded-verbatim | Install a spy, deliver a `postMessage` with a known payload | The spy receives that payload unchanged |
| wpvc-029 | set-state-persists-valid-json | Install a spy, deliver a `setState` with a JSON-representable value | The current page state updates to that value's JSON text; the spy fires once |
| wpvc-030 | set-state-drops-invalid-json-without-erasing | With a known page state, install a spy, deliver a `setState` with a non-JSON value | The page state is unchanged; the spy does not fire; the failure is logged as an error |
| wpvc-031 | relay-holds-delegate-weakly | Assign a panel as the relay's delegate, then release every other strong reference to the panel | The panel is reclaimed; the relay's delegate reads absent afterward |
| wpvc-032 | relay-drops-unrecognized-messages | Deliver a script message whose body is not a dictionary | The panel's message handler is never called |
| wpvc-033 | relay-defaults-missing-body-to-null | Deliver a script message dictionary with a valid `kind` and no `body` entry | The panel's message handler is called with a null body |
| wpvc-035 | javascript-permission-reevaluated-per-navigation | Compute preferences with `enableScripts == true`, flip to `false`, compute again | First result allows scripts; second does not |
| wpvc-036 | own-scheme-navigation-allowed | Evaluate policy for a navigation whose URL uses the panel's own scheme | Allowed |
| wpvc-037 | unmatched-navigation-cancelled | Evaluate policy for (a) no URL, (b) an unrelated scheme, (c) an `https://` URL not from link activation | All three cancelled |
| wpvc-038 | link-activation-opens-externally-not-in-place | Evaluate policy for a link-activated `https://` navigation, with a spy external-open handler | Cancelled in place; the spy is called once with that URL |
| wpvc-039 | external-open-rate-limited | With a long rate-limit interval, trigger two link activations back to back | First opens externally; second is cancelled without opening, and logs the drop |
| wpvc-040 | external-open-state-scoped-per-panel | Rate-limit one panel, then immediately trigger a link activation on a second, independent panel | The second panel's external-open handler is still called |
| wpvc-041 | reveal-forwards-when-listener-present | Install a reveal listener, request a reveal with `preserveFocus: true` | The listener is called once with `true` |
| wpvc-042 | reveal-deferred-before-first-placement | With no reveal listener ever installed, request a reveal with `preserveFocus: false` | No crash, no callback; the request is retained (see wpvc-045) |
| wpvc-043 | reveal-after-unplacement | Install then clear the reveal listener, request a reveal with `preserveFocus: true` | No crash, no callback, and nothing is retained for replay |
| wpvc-044 | reveal-noop-once-disposed | Dispose the panel, then request a reveal with `preserveFocus: true` | No callback fires and nothing is retained |
| wpvc-045 | installing-reveal-listener-replays-deferred-reveal | Request a reveal with `preserveFocus: true` before any listener exists, then install a listener | The newly installed listener is invoked once, immediately, with `true` |
| wpvc-046 | dispose-idempotent | Install a removal listener, dispose the panel twice | The removal listener is invoked once (from the first call); the second call performs no further webview teardown and does not call the removal listener again |
| wpvc-047 | dispose-tears-down-the-webview-state | Dispose the panel after constructing the view | The navigation delegate is cleared, the message handler is removed, and empty content is loaded |
| wpvc-048 | dispose-fires-did-dispose-once | Install a spy, dispose the panel | The spy fires exactly once |
| wpvc-049 | deferred-removal | (a) Dispose the panel with no removal listener ever installed; (b) install then clear a removal listener, then dispose the panel | (a) a removal is retained for replay; (b) none is retained |
| wpvc-050 | dispose-forwards-removal-when-listener-present | Install a removal listener, dispose the panel | The listener is called once |
| wpvc-051 | installing-removal-listener-replays-deferred-removal | Dispose the panel before any removal listener exists, then install a listener | The newly installed listener is invoked once, immediately |
| wpvc-052 | restoration-state-snapshots-current-values | Set `viewType`, `title`, `state` (via `setState`), and `options` to known values, read the restoration snapshot | All four match the current values |
| wpvc-053 | panel-title-defaults-empty-string | With `title` unset, read the webview object's title accessor | Returns an empty string |
| wpvc-054 | pane-title-defaults-to-view-type | With `title` unset and a known `viewType`, read this app's own pane-title accessor | Returns `viewType` |
| wpvc-055 | pane-title-change-callback-aliases-title-callback | Install a callback on this app's own pane-title change notification, then change `title` | That callback fires |
| wpvc-056 | teardown-disposes-panel | Invoke the pane-teardown call | The panel becomes disposed and `onDidDispose` fires, identically to a direct dispose call |
| wpvc-057 | automation-mode-disables-occlusion-paint-suppression | In a debug/automation build, with automation mode enabled, construct the view | The webview's window-occlusion paint suppression is disabled when the runtime supports the check, and the attempt is silently skipped otherwise; this path does not exist in a production build |
| wpvc-058 | load-host-document-noop-after-disposal | Assign a new `html` value before the view has ever been constructed | No load reaches any webview (none exists yet), and no crash occurs |
| wpvc-059 | host-document-bootstrap-precedes-extension-markup | Set `html` to a known extension markup string and construct the view | The wrapped host document's `acquireVsCodeApi()` bootstrap script appears before that markup in document order |
| wpvc-060 | host-document-absent-state-as-undefined | Construct a panel with no restored state and construct the view | The wrapped host document embeds the initial state as the literal `undefined`, not `null` |
| wpvc-061 | content-security-policy-floor | With `options.enableForms == false`, read the scheme handler's Content-Security-Policy | It contains `object-src 'none'`, `base-uri 'none'`, `frame-ancestors 'none'`, and `form-action 'none'` |
| wpvc-062 | content-security-policy-floor | With `options.enableForms == true`, read the scheme handler's Content-Security-Policy | It contains `object-src 'none'`, `base-uri 'none'`, and `frame-ancestors 'none'`, and omits `form-action 'none'` |
| wpvc-063 | reveal-deferred-request-overwritten | With no reveal listener ever installed, request a reveal with `preserveFocus: true` then with `preserveFocus: false`, then install a listener | The listener is invoked once, immediately, with `false` |
| wpvc-064 | installing-reveal-listener-replays-deferred-reveal | Request a reveal with `preserveFocus: true` before any listener exists, then dispose the panel, then install a reveal listener | The listener is still invoked once, immediately, with `true`, even though the panel is now disposed |
| wpvc-065 | panel-title-setter-assigns-through | Set the webview object's title accessor to a new string value | `title` equals that value afterward |
| wpvc-066 | relay-drops-unrecognized-messages | Deliver a script message whose body is a dictionary with an unrecognized `kind` string | The panel's message handler is never called |
| wpvc-067 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

