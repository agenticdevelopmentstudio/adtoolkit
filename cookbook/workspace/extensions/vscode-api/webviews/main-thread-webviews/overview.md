
This adaptor is the extension host's `vscode.window` surface for webviews:
`createWebviewPanel`, `registerWebviewPanelSerializer`,
`registerWebviewViewProvider`, plus two hand-over entry points, `restore` and
`resolveWebviewView`, that the host's extension installer calls when a pane
the project remembers is rebuilt before its extension has necessarily
activated. The adaptor MUST run confined to a single, serialized execution
context, matching every other such adaptor and the extension host itself,
because the values it holds are not safe to share across concurrent contexts
and every member below is invoked on the thread that made the call.

The panel record is the sole strong reference keeping a panel's
script-exposed callbacks alive — adopting, abandoning, wiring, and
forgetting a panel are the four moves of that lifecycle, and every path
through `createWebviewPanel`, `restore`, and `resolveWebviewView` funnels
through them. The serializer registry and the view-provider registry are
token-guarded — each entry pairs a registration token with the registered
callback — so that a stale disposable captured before a later registration
under the same key cannot unregister it. The workspace roots provider is
read fresh on every `createWebviewPanel` call rather than snapshotted at
construction, mirroring the workspace adaptor's own stated rule, so a
project folder opened after the extension activated is still a resource
root a new panel can read from. The shared not-implemented ledger records
every VS Code webview member this host does not honor — `enableCommandUris`,
`portMapping`, `WebviewPanel.iconPath`, `onDidChangeViewState`/
`onDidChangeVisibility` subscriptions, and a contributed view's
`resolveContext.state` — so the extension report (task 5.8) can name what
an extension quietly lost rather than an operator discovering it by
accident.

The adaptor collaborates with, but does not itself implement: the presenter
(puts a panel on screen; this adaptor never touches the platform's own
rendering layer directly), the options resolver (resolves
declared-versus-default `localResourceRoots` and builds the floor
Content-Security-Policy — the CSP construction is a collaborator fact this
adaptor never invokes), the resource URL builder (mints the
`agentic-webview://<panelID>/<path>` scheme URL `asWebviewUri` returns, with
the containment check against `localResourceRoots` happening elsewhere, in a
resource scheme handler, not in this adaptor), the coalescing event emitter
(the pub/sub relay behind `onDidReceiveMessage`, `onDidDispose`,
`onDidChangeViewState`/`onDidChangeVisibility`, every one of them built for
synchronous, same-turn delivery), the shared script call/promise/disposable
ceremony every such adaptor uses instead of its own copy, and the shared
not-implemented ledger (the deduplicated-by-member-path record described
above).

