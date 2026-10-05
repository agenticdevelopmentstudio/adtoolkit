
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/AIPluginKit/SystemMemoryMonitor.swift`,
  alongside the `MemoryPressureLevel` enum it depends on
  (`ModelFitPolicy.swift`) and its consumer `LocalInferenceGuard.swift`. It
  uses `ProcessInfo.processInfo.physicalMemory` for RAM,
  `DispatchSource.makeMemoryPressureSource` plus a dedicated
  `DispatchQueue` for the OS pressure signal, and `NSLock` to guard the
  latched value read from arbitrary threads. Nothing here is
  SwiftUI-specific — any host consumes it identically through
  `SystemMemoryMonitoring`. The level-mapping helper (`level(for:)`)
  carries no access modifier (Swift's default `internal`), so it is
  reachable from the event handler and from `@testable import
  AIPluginKit` tests, but is not part of the type's public API. The type
  is declared `final class SystemMemoryMonitor: SystemMemoryMonitoring,
  @unchecked Sendable`, asserting the cross-actor safety described by
  `concurrency-safety-is-manually-asserted` explicitly, since the compiler
  cannot verify a hand-rolled `NSLock` on its own; the event handler
  closure captures `self` weakly and returns without updating `latched`
  when `self` has already been deallocated, per
  `event-handler-guards-against-deallocated-instance`.
- **Compose**: `ActivityManager.MemoryInfo` (for total/available RAM) and
  `ComponentCallbacks2.onTrimMemory(level)` are the Android analogues of
  `ProcessInfo.physicalMemory` and the latched `DispatchSourceMemoryPressure`
  signal respectively; `onTrimMemory`'s `TRIM_MEMORY_*` levels would need
  the same collapse-to-three-tiers mapping `level(for:)` performs, and a
  `kotlinx.atomicfu`-backed field or a `synchronized` block stands in for
  `NSLock`. A plain `object` singleton stands in for `SystemMemoryMonitor.shared`.
- **React/Web**: Neither Node.js nor the browser exposes an OS memory-pressure
  latch analogous to `DispatchSourceMemoryPressure`; a Node host can read
  `os.totalmem()` for the RAM figure but has no `.warning`/`.critical`
  equivalent to subscribe to. The browser's non-standard
  `navigator.deviceMemory` gives only a coarse RAM estimate, and there is no
  standardized pressure-event API to poll or subscribe to in its place.
- **AppKit / UIKit**: Identical to the SwiftUI note — this type is
  UI-framework-agnostic; only the host application embedding `AIPluginKit`
  differs, never this contract.
- **WinUI 3**: Model `SystemMemoryMonitor` as a plain C# class exposing
  `ulong PhysicalRam` (read once via `GlobalMemoryStatusEx`, P/Invoke, or
  `Windows.System.MemoryManager.AppMemoryUsage`) and a `MemoryPressureLevel
  PressureLevel` property backed by a `lock`-guarded field (or a `volatile`
  field with `Interlocked` if only reads/writes of a single enum value are
  needed). Subscribe to
  `Windows.System.MemoryManager.AppMemoryUsageIncreased`/`AppMemoryUsageDecreased`
  events, or poll `AppMemoryUsageLevel` (`Low`/`Medium`/`High`/`OverLimit`)
  on a dedicated background `Task`/timer in place of the GCD event queue,
  and collapse that four-value enum to the three-value `MemoryPressureLevel`
  the way `level(for:)` collapses a coalesced `OptionSet` mask — deciding
  which WinUI level maps to `.warning` versus `.critical` is a new mapping
  decision this source does not answer for Windows. Use a static
  `readonly` singleton field, initialized once, for `SystemMemoryMonitor.Shared`.

