
- **SwiftUI**: not a SwiftUI concern (no view). A Swift port has no natural class or actor
  to attach to either — it is three free functions (or three `static` members of a
  `CommitFormatting` namespace) operating on `String?`. `shortSha` becomes
  `hash?.prefix(7).map(String.init)`; because Swift's `String` counts extended grapheme
  clusters rather than the UTF-16 code units JS's `slice` counts, a `hash` containing
  combining characters could yield a different substring length than the TS version —
  in practice a commit sha is plain ASCII hex, so this divergence does not surface.
- **Compose**: same non-UI framing as SwiftUI. A Kotlin port models the three functions as
  top-level `fun`s: `shortSha` as `hash?.take(7)`, `commitFirstLine` as
  `message?.substringBefore("\n")?.take(max)`, and `commitFullMessage`'s trailing-only trim
  as a custom `trimEnd { it.isWhitespace() }` (Kotlin's zero-argument `trimEnd()` behaves
  the same way, trimming only from the end) followed by `.take(max)` and an
  `.ifEmpty { null }` check.
- **React/Web** (source platform): lives at
  `packages/web/packages/status-server/src/monitor/format.ts` on the Node status backend.
  Its three functions are consumed by five deploy fetchers/webhook handlers
  (`webhook-events.ts`, `fetch-vercel.ts`, `fetch-vercel-projects.ts`, `fetch-railway.ts`,
  `fetch-cloudflare.ts`) to populate a deploy row's `commitHash` and `commitMessage`
  fields, and by two board-derivation modules (`derive-activity.ts`, `derive-problems.ts`)
  to derive a one-line `detail` string from an already-populated `commitMessage` via
  `commitFirstLine`. Only `commitFullMessage` has a dedicated test file,
  `status-server/test/format.test.ts`; `shortSha` and `commitFirstLine` have no test file
  of their own in the given source tree.
- **AppKit / UIKit**: same non-UI framing as SwiftUI. A macOS/iOS agent embedding this
  formatting has no windowing or view-layer concern of its own; it would reuse the same
  Swift free functions described under SwiftUI regardless of whether the surrounding app is
  AppKit- or UIKit-based. Any ellipsis-based visual truncation a `UILabel`/`NSTextField`
  applies at render time is a separate, presentation-layer concern from this file's
  data-layer character capping.
- **WinUI 3**: a .NET port models the three functions as `static` methods on a
  `CommitFormatting` class taking `string?` and returning `string?`. `shortSha` becomes
  `hash is { Length: > 0 } h ? h[..Math.Min(h.Length, 7)] : null` (the C# range operator, to
  match `slice`'s no-throw-on-short-input behavior exactly, rather than `Substring`, which
  throws when the requested length exceeds the string's length). `commitFirstLine` becomes
  a split on `'\n'` followed by the same range-based cap. `commitFullMessage`'s
  trailing-only strip is `Regex.Replace(message, @"\s+$", "")` (or plain
  `.TrimEnd()`, which trims all trailing Unicode whitespace and matches `\s+$` closely
  enough for commit-message text) followed by an empty-string check and the same
  range-based cap. None of `HttpClient`, `Task`/`async`, `Windows.Storage`,
  `ObservableCollection`, or `INotifyPropertyChanged` is needed: this is a synchronous,
  non-UI-bound, side-effect-free string-formatting utility with no I/O, no asynchronous
  operation, no persistence, and no live-updating collection to bind to.

