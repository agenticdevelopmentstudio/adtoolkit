
- **SwiftUI**: not a SwiftUI concern (no view). A Swift port has no natural class or actor to
  attach to — it is two free functions (or two `static` members of a `URLHelpers`-like
  namespace) operating on `String`/`String?`. `hostOf` becomes
  `Foundation.URL(string: url)?.host ?? url`; unlike JS's `new URL(...).host`, Swift's
  `URL.host` never includes the port — a Swift port that must reproduce the JS `"host:port"`
  string has to append `URL.port` itself, a real divergence worth flagging in the port.
- **Compose**: same non-UI framing as SwiftUI. A Kotlin port models the two functions as
  top-level `fun`s using `java.net.URI`, whose constructor throws `URISyntaxException` on a
  malformed string (matching the try/catch shape): `hostOf` becomes
  `runCatching { URI(url).host }.getOrDefault(url)`. As with Swift, `URI.host` excludes the
  port (a separate `.port` property returns `-1` when absent), so a Kotlin port needing the
  combined `"host:port"` form must assemble it manually.
- **React/Web** (source platform): lives at
  `packages/web/packages/status-server/src/monitor/url.ts` on the Node status backend. Its
  two exported functions are consumed by three files: `deploy-view.ts` (via
  `projectPageUrl`, to derive a deploy row's `sourceUrl`), and `sync.ts` and
  `routes/reads.ts` (via `hostOf`, to derive a stamped or reported live host). Neither
  function has a dedicated test file in the given source tree — unlike the sibling module
  `format.ts`, which has `format.test.ts`.
- **AppKit / UIKit**: same non-UI framing as SwiftUI. A macOS/iOS agent embedding this URL
  handling has no windowing or view-layer concern of its own; it would reuse the same Swift
  free functions described under SwiftUI regardless of whether the surrounding app is
  AppKit- or UIKit-based.
- **WinUI 3**: a .NET port models the two functions as `static` methods on a `UrlHelpers`
  class. `hostOf` becomes
  `Uri.TryCreate(url, UriKind.Absolute, out var u) ? u.Host + (u.IsDefaultPort ? "" : $":{u.Port}") : url`
  — .NET's bool-returning `Uri.TryCreate` replaces JS's throw-and-catch, and because
  `Uri.Host` (like Swift's and Kotlin's host accessors) excludes the port, the port must be
  appended manually via `Uri.Port`/`Uri.IsDefaultPort` to match the combined `host:port`
  string JS's `URL.host` returns. `projectPageUrl` becomes a similar `Uri.TryCreate` guard,
  checking `u.Host == "vercel.com"` and splitting `u.AbsolutePath` on `'/'` with
  `StringSplitOptions.RemoveEmptyEntries` to get the segment array, then reconstructing
  `$"{u.GetLeftPart(UriPartial.Authority)}/{parts[0]}/{parts[1]}"` when 3 or more segments
  result. None of `HttpClient`, `System.Text.Json`, `Windows.Storage`, `Task`/`async`,
  `ObservableCollection`, or `INotifyPropertyChanged` is needed: this is a synchronous,
  non-UI-bound, side-effect-free pair of string-parsing utilities with no I/O, no
  asynchronous operation, and no persistence or live-updating collection to bind to.

