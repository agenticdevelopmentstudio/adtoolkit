
This adaptor raises and logs hardcoded English string literals; none carries a localization key, `String(localized:)` call, or String Catalog entry. Every raised message reaches the extension as a thrown JavaScript error, so an extension author sees the literal English text regardless of locale; every logged message reaches only the host's own log.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `vscode.window.createWebviewPanel is unavailable: this extension's host has been torn down.` | Raised by `createWebviewPanel` after the adaptor is torn down. |
| (none — literal only) | `vscode.window.createWebviewPanel's first argument must be a view type string.` | Raised when the first argument is missing or not a string. |
| (none — literal only) | `vscode.window.createWebviewPanel's second argument must be a title string.` | Raised when the second argument is missing or not a string. |
| (none — literal only) | `vscode.window.createWebviewPanel could not open a panel for view type '<viewType>': this app's windows belong to open projects, and none is open.` | Raised when the presenter has nowhere to put the panel. |
| (none — literal only) | `vscode.window.createWebviewPanel could not build a panel object for view type '<viewType>'.` | Raised when a presented panel could not be given a script object. |
| (none — literal only) | `vscode.window.registerWebviewPanelSerializer is unavailable: this extension's host has been torn down.` | Raised by `registerWebviewPanelSerializer` after teardown. |
| (none — literal only) | `vscode.window.registerWebviewPanelSerializer's first argument must be a view type string.` | Raised when the first argument is not a string. |
| (none — literal only) | `vscode.window.registerWebviewPanelSerializer's second argument must be an object with a deserializeWebviewPanel(panel, state) method.` | Raised when the second argument lacks a callable `deserializeWebviewPanel`. |
| (none — literal only) | `vscode.window.registerWebviewViewProvider is unavailable: this extension's host has been torn down.` | Raised by `registerWebviewViewProvider` after teardown. |
| (none — literal only) | `vscode.window.registerWebviewViewProvider's first argument must be a view id string.` | Raised when the first argument is not a string. |
| (none — literal only) | `vscode.window.registerWebviewViewProvider's second argument must be an object with a resolveWebviewView(webviewView, context, token) method.` | Raised when the second argument lacks a callable `resolveWebviewView`. |
| (none — literal only) | `vscode.Webview.asWebviewUri needs a Uri.` | Raised when `asWebviewUri`'s argument is missing or unparseable. |
| (none — literal only, log only) | `<extension> asked for a webview panel of type <viewType>, but there is no window to put it in` | Logged at error level alongside the "no window open" raise. |
| (none — literal only, log only) | `A panel of view type <viewType> for <extension> could not be given a script object; it was closed again` | Logged at error level alongside the "could not build a panel object" raise. |
| (none — literal only, log only) | `The <panel-or-view kind> <identifier> was closed before <extension> could fill it; it is not handed over` | Logged at notice level when logging a refused hand-over. |
| (none — literal only, log only) | `<extension> registered a second webview panel serializer for view type <viewType>; the later one wins` | Logged at error level on a duplicate serializer registration. |
| (none — literal only, log only) | `<extension> registered a second webview view provider for view id <viewID>; the later one wins` | Logged at error level on a duplicate provider registration. |
| (none — literal only, log only) | `<extension>'s deserializeWebviewPanel threw for view type <viewType>: <reason>` / `could not be invoked for view type <viewType>` | Logged at error level on `restore`'s throw/unavailable outcomes. |
| (none — literal only, log only) | `<extension>'s resolveWebviewView threw for view id <viewID>: <reason>` / `could not be invoked for view id <viewID>` | Logged at error level on `resolveWebviewView`'s throw/unavailable outcomes. |

