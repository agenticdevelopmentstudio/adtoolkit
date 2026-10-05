
**Decision**: `ExtensionWebviewPresenting` is a single-method protocol (`presentWebviewPanel(_:) -> (any ExtensionWebviewPanel)?`) rather than separate create/place/reveal steps or a class hierarchy.
**Rationale**: the seam mirrors the four presenters `MainThreadWindow` already takes (message, quick pick, input box, status bar item) — a webview panel needs the same all-or-nothing "build it, place it, show it, hand back a handle" contract, with a `nil` return as the seam's only failure signal, matching the fail-fast style the other four presenters already use. Keeping the AppKit-specific placement decision out of this protocol (it lives in `PaneWebviewPresenter`'s `place` closure instead) keeps the framework layer that owns the protocol free of the app's own pane-tree concerns.
**Approved**: pending

**Decision**: `ExtensionWebviewPanel` exposes `isDisposed` as a synchronously readable property rather than relying on `onDidDispose` alone.
**Rationale**: two independent call sites in `MainThreadWebviews` — `restore` after a relaunch and `resolveWebviewView` for a contributed view — need to ask, before acting, whether a panel handed back to them is still alive. A callback fired once at disposal cannot answer a question asked after the fact; only a readable flag can.
**Approved**: pending

