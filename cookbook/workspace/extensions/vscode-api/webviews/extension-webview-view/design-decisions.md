
**Decision**: The completion closure passed to `resolve` sets a flag (`isResolved`) that a separate method (`adoptPanelIfResolved()`) re-checks, rather than swapping content directly from inside the completion closure.
**Rationale**: `resolve` can call the completion synchronously, while `resolve` is still on the call stack and the returned panel has not yet been assigned to the `panel` property; swapping content immediately from inside the closure would read a still-nil `panel`. The flag defers the actual swap until `adoptPanelIfResolved()` runs again at the end of `viewDidLoad()`, after `panel` is assigned.
**Approved**: pending

**Decision**: `paneContentWillBeDiscarded()` sets its discard flag before forwarding to the panel.
**Rationale**: Disposing the panel fires `onRemovalRequested`, which is wired to rebuild a placeholder; without the flag set first, a pane on its way out of the window would have a placeholder rebuilt into it moments before being deallocated.
**Approved**: pending

**Decision**: (AppKit/UIKit) The resolver this component depends on is a closure typealias (`ContributedWebviewResolving`) rather than a protocol.
**Rationale**: It is one verb with one production implementation, so a protocol would exist for a single conformer; taking it as a closure parameter also lets it be supplied to this component after construction, without needing a stateful lookup type. See `adtoolkit://cookbook/workspace/extensions/vscode-api/webviews/webview-panel-view` for the panel this closure returns.
**Approved**: pending

**Decision**: This component wraps the panel rather than being the webview surface itself.
**Rationale**: An unloaded `WKWebView` is a blank white rectangle. Wrapping it lets the pane show an explanatory placeholder until an extension actually resolves a provider, and go back to that explanation if the panel is later disposed — without which "installed, but nothing registered yet" would be indistinguishable from "broken." (See **Accessibility**'s Announce state changes for the one gap this wrapping does not close: the swap between those two readable states carries no assistive-technology announcement.)
**Approved**: pending

