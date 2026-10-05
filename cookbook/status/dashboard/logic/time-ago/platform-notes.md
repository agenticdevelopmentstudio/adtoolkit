
- **SwiftUI**: a free function taking `Date` values, or `Date.RelativeFormatStyle` if exact
  output parity is not needed. Parse `iso` with `Date.ISO8601FormatStyle`, which throws
  rather than yielding `NaN`, so a port has to choose explicitly whether to return `NaNd`.
  Drive "now" from `TimelineView(.periodic(from:by: 30))` to match `useNow`.
- **Compose**: a top-level `fun timeAgo(iso: String, nowMs: Long): String` using
  `java.time.Instant.parse` (throws `DateTimeParseException`) and `Long` floor division;
  supply `nowMs` from a `produceState` loop with a 30 s `delay`.
- **React/Web** (source platform): `src/lib/time-ago.ts` with vitest coverage in
  `src/lib/time-ago.test.ts`; components pair it with the `useNow` hook so labels re-render
  on a 30 s tick instead of calling `Date.now()` during render. A copy with the same body
  lives in the status server.
- **AppKit / UIKit**: the same Swift function feeds an `NSTextField` or `UILabel`; refresh
  it with a repeating `Timer` rather than on each layout pass.
- **WinUI 3**: a `public static string TimeAgo(string iso, long nowMs)` in a plain C#
  helper class. Parse with `DateTimeOffset.TryParse` (returning `false` is the port's cue
  to emit `NaNd` for parity) and compute seconds with integer division, or subtract
  `DateTimeOffset` values and use `TimeSpan.TotalSeconds` with `Math.Floor`. Bind the
  label through an `x:Bind` function binding against a view-model `Now` property that
  raises `INotifyPropertyChanged.PropertyChanged` from a `DispatcherQueueTimer` ticking
  every 30 s. `HttpClient`, `System.Text.Json`, `Windows.Storage` and `Task`/`async` are
  not needed, since the function has no I/O.

