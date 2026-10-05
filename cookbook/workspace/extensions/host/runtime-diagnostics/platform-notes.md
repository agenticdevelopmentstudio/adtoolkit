
- **SwiftUI**: The three pieces are implemented as `JITAvailability`,
  `UpstreamDivergence` (with its nested `Detection` enum and companion
  `UpstreamDivergenceHit`), and `UpstreamDivergenceLedger`, in
  `packages/apple/AgenticToolkit/Core/Diagnostics/`, part of the
  `AgenticToolkitCore` framework target. `JITAvailability` is a `Sendable,
  Hashable` struct with a public initializer that assigns its two `Bool`
  properties (`isHardenedRuntime`, `hasJITEntitlement`) directly; its
  `current` is a `static let`, memoized once by Swift's own thread-safe
  static-initialization guarantee, backed by a `probe()` that performs a
  fresh read on every call. `readHardenedRuntimeFlag()` calls
  `SecCodeCopySelf`, then `SecCodeCopyStaticCode`, then
  `SecCodeCopySigningInformation` with `kSecCSSigningInformation`, reads the
  `kSecCodeInfoFlags` entry as a `UInt32`, and tests it against the literal
  mask `0x0001_0000` (`kSecCodeSignatureRuntime`, not exposed to Swift),
  returning `false` on any `guard ... else` failure. `readJITEntitlement()`
  calls `SecTaskCreateFromSelf(nil)` and `SecTaskCopyValueForEntitlement`,
  returning `false` if either fails to produce a `Bool`. `logIfDegraded()`
  forces evaluation of a private `static let hasLogged` closure — a Swift
  static stored property whose initializer runs exactly once regardless of
  concurrent first callers — to log at most once per process, marking the
  message `privacy: .public`. `UpstreamDivergence` is a `Sendable, Hashable,
  Identifiable, Codable` struct; `Detection` is a `String`-backed,
  `Sendable, Hashable, Codable` enum. `UpstreamDivergenceHit.count`
  accumulation uses Swift's `+`, which traps on signed-integer overflow
  rather than saturating or wrapping, since the source performs no
  `addingReportingOverflow` or clamping of its own. `UpstreamDivergenceLedger`
  is declared `final class UpstreamDivergenceLedger: @unchecked Sendable`,
  uses an `NSLock` (`lock`) to guard its `rows` dictionary and a second
  `NSLock` (`publishLock`) around `publish()`'s snapshot-and-send step (the
  ordering fix described in Design Decisions), and publishes through a
  Combine `CurrentValueSubject`. Both `JITAvailability` and
  `UpstreamDivergenceLedger` obtain their logger through a shared
  `Loggable` protocol's default `makeLogger()`, which supplies OSLog
  category equal to the conforming type's own name and subsystem
  `Bundle.main.bundleIdentifier`. Nothing here is SwiftUI-specific — any
  host consumes it identically.
- **Compose**: There is no Android analogue to macOS's hardened runtime or
  to a per-entitlement JIT gate — ART's own JIT/AOT compilation strategy is
  a system-level decision, not an app-declared capability, so
  `JITAvailability` has no Kotlin equivalent to port; a port would document
  the absence rather than translate it. `UpstreamDivergence` and
  `UpstreamDivergenceHit` translate directly to Kotlin `data class`es. For
  `UpstreamDivergenceLedger`, a `synchronized` block or `kotlinx.atomicfu`
  lock stands in for `NSLock`, `kotlinx.coroutines.flow.MutableStateFlow`
  stands in for `CurrentValueSubject` (both deliver their current value
  immediately to a new collector), and a plain Kotlin `object` singleton
  stands in for `UpstreamDivergenceLedger.shared`.
- **React/Web**: Browsers need no entitlement to let a JavaScript engine
  compile code, so `JITAvailability` has no web equivalent to port; the
  nearest analogous gate is a page's Content-Security-Policy
  `script-src` directive controlling `unsafe-eval`/WebAssembly compilation,
  which is a page-level policy, not a per-process code-signature reading, so
  it does not map onto this type's contract. `UpstreamDivergence` translates
  to a `readonly` TypeScript interface array; `UpstreamDivergenceLedger`
  translates to a class wrapping a `Map` (in place of the `Key`-keyed
  dictionary) and an RxJS `BehaviorSubject` (the direct analogue of
  `CurrentValueSubject`, since both replay their latest value to a new
  subscriber) in place of manual lock-guarded state, since JavaScript's
  single-threaded event loop needs no `NSLock` equivalent at all.
- **AppKit / UIKit**: Identical to the SwiftUI note — none of the three
  types is UI-framework-specific; only the host application embedding
  `AgenticToolkitCore` differs, never this contract. (`JITAvailability`'s
  own consumer, `ExtensionHost.swift`, happens to be an AppKit-hosted,
  macOS-only feature, but that is a fact about the caller, not this
  component.)
- **WinUI 3**: Windows has no direct analogue to
  `com.apple.security.cs.allow-jit` or the hardened runtime flag — code
  integrity on Windows is governed by Authenticode signing and, for packaged
  apps, MSIX package capabilities and WDAC/AppLocker policy, none of which
  expose a single per-app "is JIT allowed" bit the way a macOS entitlement
  does; a Windows port has no established source of truth to read in
  `JITAvailability`'s place and would need a new decision, not a
  translation. Model `UpstreamDivergence` as a C# `record` implementing
  `IEquatable<T>` with a nested `enum Detection { Counted, Declared }`, and
  `UpstreamDivergenceHit` the same way. Model `UpstreamDivergenceLedger` as
  a class backed by a `lock`-guarded `Dictionary<(string, string),
  UpstreamDivergenceHit>` (or a `ConcurrentDictionary` if lock-free reads are
  wanted instead), exposing its live rows through `System.Reactive.Subjects.BehaviorSubject<IReadOnlyList<UpstreamDivergenceHit>>`
  (Rx.NET's direct analogue of `CurrentValueSubject`) rather than
  `ObservableCollection`, since what is needed is "replay the latest full
  snapshot to a new subscriber," not incremental collection-changed
  notifications. Use `Microsoft.Extensions.Logging.ILogger<T>`, categorized
  by type the way `Loggable` categorizes by `type(of: self)`, in place of
  `OSLog`'s subsystem/category pair.

