
**Decision**: One class combines the panel model and its view controller, rather than a model and a view controller behind a shared protocol.
**Rationale**: The panel is the pane's content, its title is the pane's title, and disposing it is closing the pane; splitting them would add a protocol between two objects with one lifetime that nothing else would ever implement.
**Approved**: pending

**Decision**: The reveal and removal callbacks each replay exactly one deferred call the moment they are first installed, keyed by whether the panel has ever been placed.
**Rationale**: An extension's own restore path can call `panel.reveal()` or dispose the panel before its presenter has had any chance to install these callbacks, because that call runs to completion first; dropping the call would silently strand a reveal or a removal the caller genuinely asked for.
**Approved**: pending

**Decision**: The script-execution flag is set on a freshly created `WKWebViewConfiguration` in `loadView()` and re-evaluated per navigation, rather than written to the web view's `configuration` after construction.
**Rationale**: `WKWebView.configuration` is `@NSCopying` — its getter returns a copy — so a later write there is silently discarded and never reaches WebKit; this was a real defect the source's own comments describe (turning scripts off on a running panel used to do nothing at all).
**Approved**: pending

**Decision**: The web view's website data store is non-persistent, and no second, app-level persistence path exists for a page's own `localStorage`.
**Rationale**: `setState`/`getState` is the one persistence contract a webview author writes against; a second, half-working persistence mechanism that survives some restarts and not others is worse than none.
**Approved**: pending

**Decision**: `post(message:)` validates the message against a postability check before dispatching it, rather than relying on error-trapping around the dispatch call.
**Rationale**: WebKit raises an uncatchable exception for an unbridgeable argument, which would take the whole process down; validating first turns a crash into a dropped message and a `false` return.
**Approved**: pending

**Decision**: The JSON-validity rule `setState` uses is stricter, and different, than the postability rule `post(message:)` uses.
**Rationale**: The two values go to different places — `setState`'s value is serialized to text for storage, while `post`'s value goes straight to a JavaScript engine — so a page calling `setState` with a date is silently dropped (JSON has no date type) while the identical value passed to `post(message:)` succeeds. This is an intentional asymmetry traceable to what each value is for, not an inconsistency to fix.
**Approved**: pending

**Decision**: A link click to `http`/`https` is redirected to the user's external browser rather than allowed to navigate the panel in place, and is rate-limited per panel.
**Rationale**: Navigating in place would replace the extension's page with a web page holding the panel's own origin; and link activation is reported identically for a script-triggered click and a real one, so an unthrottled page could open unbounded external windows with no user action able to stop it.
**Approved**: pending

**Decision**: The `ExtensionWebviewPanel` title accessor falls back to an empty string when `title` is unset, while the `PaneTitleProviding` title accessor falls back to `viewType` in the same circumstance.
**Rationale**: The two protocols serve different callers — the former answers the extension API's own title property, which upstream treats as a plain string, while the latter answers this app's pane chrome, which needs a non-empty placeholder rather than a blank tab label before a title has ever been set.
**Approved**: pending

**Decision**: The DEBUG-only window-occlusion override pokes a private selector by name, guarded by a compile-time check and a runtime `responds(to:)` check, rather than shipping it unconditionally.
**Rationale**: WebKit stops painting into a window the window server reports occluded, which automation deliberately does to every window during screenshot capture; a real user's occluded window should keep that battery-saving behavior, so this private-API use is confined to debug builds and skipped outright wherever the selector does not exist.
**Approved**: pending

**Decision**: The script message handler is a separate relay object holding the panel weakly, rather than the panel registering itself as its own handler.
**Rationale**: The user content controller retains its handlers, the configuration retains the controller, the web view retains the configuration, and the panel retains the web view; a panel that was its own handler would never deallocate, holding an entire web content process past its pane's lifetime.
**Approved**: pending

