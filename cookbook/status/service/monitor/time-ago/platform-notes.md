
- **SwiftUI**: not a SwiftUI concern (no view). A Swift port has no natural class or actor
  to attach to — it is one free function, `func timeAgo(iso: String, nowMs: Double) -> String`
  (or, more idiomatically, one that takes a `Date` "now" rather than raw milliseconds); the
  four-bucket threshold chain (`< 60`, `< 60`, `< 24`) ports directly with integer division
  and `floor`. Parsing `iso` requires `ISO8601DateFormatter` (or `Date.ISO8601FormatStyle`),
  which returns `nil` on an unparseable string — unlike the source's silent `NaN`
  fall-through, a Swift port is forced to consciously decide what to do with that `nil`,
  which `no-iso-validation` leaves to the caller in the source.
- **Compose**: same non-UI framing as SwiftUI. A Kotlin port models `timeAgo` as a
  top-level `fun timeAgo(iso: String, nowMs: Long): String`, parsing `iso` with
  `java.time.Instant.parse` (which throws `DateTimeParseException` on malformed input,
  again forcing an explicit decision the source's silent fall-through avoids), then the
  same floor-divide bucket chain using `Long` arithmetic.
- **React/Web** (source platform): lives at
  `packages/web/packages/status-server/src/monitor/time-ago.ts` on the Node status
  backend. Its only two callers in the given source tree are `integrations.ts` (labeling
  the freshness of the last stored health-check timestamp) and `fetch-vercel-projects.ts`
  (labeling the age of a stale production project's last live build); no dedicated test
  file exercises `timeAgo` anywhere in the given source tree.
- **AppKit / UIKit**: same non-UI framing as SwiftUI; no windowing or view-layer concern
  applies. Any label (`UILabel`/`NSTextField`) that displays `timeAgo`'s output does so
  verbatim, with no additional truncation or styling needed since the string is already a
  short, fixed-format token.
- **WinUI 3**: a .NET port models `timeAgo` as a `static` method — for example
  `public static string TimeAgo(DateTimeOffset iso, DateTimeOffset now)` — preferring
  `DateTimeOffset` subtraction (`(now - iso).TotalSeconds`) over round-tripping through raw
  milliseconds, then the same floor-divide bucket chain via `Math.Floor`.
  `DateTimeOffset.Parse` throws `FormatException` on a malformed `iso` string — again an
  explicit decision a WinUI 3 port must make where the source silently falls through to
  `NaNd`. None of `HttpClient`, `Task`/`async`, `Windows.Storage`, `ObservableCollection`,
  or `INotifyPropertyChanged` is needed: this is a synchronous, non-UI-bound,
  side-effect-free string-formatting utility with no I/O, no asynchronous operation, and no
  persistence.

