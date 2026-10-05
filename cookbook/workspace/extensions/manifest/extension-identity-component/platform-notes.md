
- **SwiftUI**: Source:
  `packages/apple/AgenticToolkit/Core/Extensions/ExtensionIdentityComponent.swift`.
  The predicate is plain `Foundation` — `String.isEmpty`,
  `String.hasPrefix(_:)`, `String.contains(_:)`, and `String.unicodeScalars`
  — with no SwiftUI dependency; a SwiftUI-hosted caller (for example a
  settings screen listing installed extensions) calls
  `ExtensionIdentityComponent.isSafe(_:)` directly and synchronously, on any
  thread. `ExtensionIdentityComponent` declares no `Sendable` conformance
  and no actor or `@MainActor` isolation; it has no cases and therefore no
  instance state, and `isSafe` is a `static func` operating only on its
  `String` parameter and `Bool` return value, both `Sendable` value types —
  which is why it is callable synchronously from any thread or actor
  context without additional synchronization.
- **Compose**: On Kotlin/Android, port the guard chain to a plain `object`
  (Kotlin's namespace-only singleton, the equivalent of the source's
  case-less `enum`) exposing `fun isSafe(value: String): Boolean`, using
  `String.isEmpty()`, `String.startsWith(".")`, and `String.contains(...)`
  for the three separators, then iterating `value.codePoints()` and testing
  each code point against `< 0x20 || == 0x7F`, mirroring the source's
  scalar-level check.
- **React/Web**: In TypeScript, port to a pure function
  `isSafe(value: string): boolean` using `value.length === 0`,
  `value.startsWith(".")`, and `value.includes(...)` for the three
  separators, then testing every entry of `Array.from(value)` (iterating by
  code point, not UTF-16 code unit, since a `charCodeAt` loop would split a
  surrogate pair) against the same `< 0x20 || === 0x7F` range.
- **AppKit / UIKit**: No divergence from the SwiftUI bullet above — the
  source is framework-agnostic `Foundation` code called identically from an
  AppKit-hosted (macOS) or UIKit-hosted (iOS) caller. `AgenticToolkitCore`
  itself targets only macOS today, so an iOS caller would first need the
  type made available to an iOS target, but `isSafe` itself needs no
  AppKit/UIKit-specific change.
- **WinUI 3**: Port to a plain static method, e.g.
  `internal static class ExtensionIdentityComponent { internal static bool IsSafe(string value) { ... } }`
  — no XAML, control, or visual state is involved. Use
  `string.IsNullOrEmpty(value)`, `value.StartsWith(".", StringComparison.Ordinal)`,
  and `value.Contains(...)` for the three separators, each with
  `StringComparison.Ordinal` (never a culture-aware comparison, since the
  check compares literal separator characters, not display equivalence).
  Enumerate code points with `.NET`'s `value.EnumerateRunes()` — `Rune` is
  the code-point-level equivalent of Swift's `Unicode.Scalar` — testing
  `rune.Value < 0x20 || rune.Value == 0x7F`; a plain `foreach (char c in value)`
  loop would iterate UTF-16 code units instead of code points and mis-handle
  any value outside the Basic Multilingual Plane, so `EnumerateRunes()` is
  the correct starting point, not a `char` loop. Callers reach it from
  `VSIXInstaller`- and `OpenVSXClient`-equivalent services before building a
  directory name (`System.IO.Path.Combine`) or a `Uri`, exactly as in
  `VSIXInstaller.swift` and `OpenVSXClient.swift`.

