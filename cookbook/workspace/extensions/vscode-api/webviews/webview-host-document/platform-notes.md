
- **SwiftUI**: `WKWebView` has a SwiftUI wrapper via `NSViewRepresentable`
  (macOS) or `UIViewRepresentable` (iOS); this file's string-assembly logic
  is UI-framework-agnostic and unchanged under SwiftUI — only the code that
  owns the `WKWebView` and calls
  `webView.loadHTMLString(WebviewHostDocument.html(wrapping:initialState:), baseURL:)`
  moves into the representable's `updateNSView`/`updateUIView`. The
  `WKScriptMessageHandler` registration against `messageHandlerName` has no SwiftUI equivalent and stays as imperative
  `WKUserContentController` setup inside the representable's coordinator.
- **Compose**: Android has no `WKWebView`/`WKUserContentController`
  equivalent; the nearest composition is Jetpack Compose's `AndroidView`
  wrapping a platform `android.webkit.WebView`, with
  `WebView.addJavascriptInterface` (a method annotated `@JavascriptInterface`)
  replacing the `WKScriptMessageHandler` bridge the bootstrap script
  addresses through `window.webkit.messageHandlers.agenticWebview`. The head-insertion and escaping logic ports directly,
  since it is plain string manipulation with no WebKit dependency.
- **React/Web**: If the "webview" is itself an `iframe` rather than a native
  WebView, the DOM's own `postMessage`/`onmessage` pair replaces the
  `WKScriptMessageHandler` bridge entirely, and there is no HTML-string
  injection step at all — the host page and the framed page communicate
  directly. The `acquireVsCodeApi`-shaped bootstrap this file generates is worth keeping only if the product wants VS Code
  extension source code to run unmodified inside a web-hosted panel.
- **AppKit / UIKit (source)**: This file is Foundation-only (no
  `AppKit`, `UIKit`, or `WebKit` import) — the `WKWebView` and
  `WKUserContentController.add(_:name:)` calls that actually consume
  `WebviewHostDocument.html(wrapping:initialState:)` ("building the host
  document" above) and `messageHandlerName` ("the message channel name"
  above) live in
  `packages/apple/AgenticToolkit/macOS/Features/Extensions/Webview/WebviewPanelViewController.swift`,
  which is macOS/AppKit-only in this repository today; there is no
  iOS/UIKit counterpart under this package. "The head-location search"
  above is `headStartTagEnd(in:)`; "escaping a value for script-element
  embedding" above is `escapedForScriptElement(_:)`; "the send-message
  primitive" above is `send(kind:body:)`. `WebviewHostDocument` is declared
  with no `Sendable` conformance, no `actor`, and no `@MainActor`
  isolation; it declares zero cases and only `static` members, so it holds
  no stored instance state, and its lack of an isolation annotation has no
  observable effect — every member is callable from any actor or thread
  without crossing an isolation boundary a caller could violate. The nested
  `MessageKind` is declared explicitly `Sendable` and `CaseIterable`, with
  raw values `"postMessage"` and `"setState"`.
- **WinUI 3**: `Microsoft.Web.WebView2` (the `WebView2` control) replaces
  `WKWebView`. The closer match to this file's actual bridge shape — a
  single named channel carrying a `kind`/`body` pair — is
  `CoreWebView2.WebMessageReceived` paired with the page calling
  `chrome.webview.postMessage`/`window.chrome.webview.postMessage` (WebView2's
  own bridge global), rather than `AddHostObjectToScript`. The bootstrap
  script's `window.acquireVsCodeApi`/`postMessage`/`getState`/`setState`
  shim is generated identically via C# string interpolation
  before being handed to `CoreWebView2.NavigateToString(html)`. The
  head-insertion scan (`headStartTagEnd`) ports as a
  `string`-index walk using `IndexOf`/`Span<char>` with the same
  case-insensitive `<head`-vs-`<header>` and quoted-attribute bailout rules;
  `escapedForScriptElement` ports as a `switch` over `char`
  values feeding a `StringBuilder`, producing the equivalent `\u` hex
  escape for each blocked character. `System.Text.Json`'s
  `JsonSerializer.Serialize` is what a caller uses to produce `initialState`
  before it ever reaches this function — this file's own contract is
  unaffected either way, since it treats `initialState` as opaque,
  already-serialized text.

