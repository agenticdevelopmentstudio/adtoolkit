
- **SwiftUI**: the source (`WebviewResourceURL.swift`) is plain Foundation —
  `URL`, `URLComponents`, and the `Error`/`LocalizedError` protocols — with
  zero dependency on SwiftUI or any view-layer framework. It sits in
  `AgenticToolkitCore` specifically so the access decision is testable
  without `WebKit`, per the source's own closing comment; a port that keeps
  this component in Swift needs nothing beyond `Foundation` plus whatever
  Swift form `ExtensionResourcePath` takes on that platform. Concretely:
  `WebviewResourceURLError` is a `public enum` conforming to `Error` and
  `Equatable`, with exactly the three cases named in the recipe's error-case
  requirement (`unexpectedScheme(String)`, `unexpectedPanel(declared:
  String, expected: String)`, `outsideLocalResourceRoots(resolved: String)`),
  and it additionally conforms to `LocalizedError` for the `errorDescription`
  behavior in error-message. `WebviewResourceURL.Target` is a nested public
  enum conforming to `Equatable`, with cases `hostDocument` (no payload) and
  `file(URL)`. Both `hostDocumentURL(panelID:)` and `url(forFile:panelID:)`
  build their result through `URLComponents` from the decoded `panelID` and
  path values, letting `URLComponents` percent-encode both; the fixed
  fallback for an unrepresentable panel id is the literal value
  `URL(fileURLWithPath: "/")`, returned in place of the `nil` `URLComponents`
  would otherwise produce. Neither `WebviewResourceURLError`,
  `WebviewResourceURL`, nor its nested `Target` declares a `Sendable`
  conformance or any actor / `@MainActor` isolation in the source; every
  stored payload (`String`, `URL`) is itself `Sendable`, and
  `WebviewResourceURL` declares no case and cannot be instantiated, so it
  holds no stored state — which is what backs the recipe's
  safe-for-concurrent-access requirement.
- **Compose**: model `WebviewResourceURLError` as a Kotlin `sealed class`
  with the same three payload shapes, and `WebviewResourceURL` as a Kotlin
  `object` namespace. Build and parse the scheme with `android.net.Uri`
  (`Uri.getScheme()`, `Uri.getHost()`, `Uri.getPath()`) rather than a raw
  string split, since `Uri` already performs the percent-decoding this file
  relies on. Android's `WebViewAssetLoader` or a custom
  `WebViewClient.shouldInterceptRequest` override is the analogue of the
  `WKURLSchemeHandler` this file's containment decision serves; neither
  enforces containment on its own, so the port must still call the
  containment decision explicitly from that override.
- **React/Web**: for a browser or Electron-hosted extension host, register a
  custom protocol handler (Electron's `protocol.handle`, or a Service
  Worker's `fetch` handler for a web-hosted equivalent) and reproduce the
  same three-step decision — scheme check, then origin/panel check against
  the request's URL authority, then a component-wise containment check
  against each declared root using Node's `path` module (never
  `String.prototype.startsWith`, for the reason `ExtensionResourcePath`'s
  own Platform Notes give). There is no browser API that grants a custom
  scheme the origin isolation `agentic-webview`'s authority-per-panel design
  achieves on WebKit; an Electron `BrowserView` per panel, or a Service
  Worker scoped per panel, is the nearest equivalent.
- **AppKit / UIKit**: identical to the SwiftUI note — the component depends
  on neither AppKit nor UIKit, so a macOS or iOS host consumes the same
  `AgenticToolkitCore` type directly with no translation needed; only the
  `WKURLSchemeHandler` that calls it (outside this file) is UIKit/AppKit-
  adjacent WebKit code.
- **WinUI 3**: there is no single .NET or Windows App SDK type that performs
  this file's exact scheme-then-panel-then-containment decision. Model
  `WebviewResourceURLError` as a small `.NET` exception type (or a
  discriminated union via a base `record`) carrying the same three payload
  shapes, and `WebviewResourceURL` as a `static class`. WebView2
  (`CoreWebView2.WebResourceRequested`, or
  `CoreWebView2.SetVirtualHostNameToFolderMapping` for the simple case) is
  the analogue of `WKURLSchemeHandler`, but it enforces no containment of
  its own: a port must parse the request's `Uri` (`Uri.Host` for the panel
  id, `Uri.AbsolutePath` for the file path) inside the
  `WebResourceRequested` handler and call the containment decision
  explicitly, using `Path.GetFullPath` plus an explicit symlink/junction
  resolution step chained before the comparison — `Path.GetFullPath` alone
  does not resolve symlinks the way `resolvingSymlinksInPath()` does in the
  source — and compare with `Path.GetRelativePath`, never
  `string.StartsWith`, for the same component-versus-string-prefix reason
  `ExtensionResourcePath`'s own WinUI 3 note gives. `HttpClient`,
  `System.Text.Json`, `Task`/`async`, `ObservableCollection`, and
  `INotifyPropertyChanged` all have no role here: every operation in the
  source is synchronous, non-networked, non-serializing, and returns a
  value rather than raising a change notification.

