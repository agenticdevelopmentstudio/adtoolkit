
- **SwiftUI**: A port keeps the planners (`plan.ts`, `builder-match.ts`) as
  pure, synchronous Swift functions over `struct`/`enum` value types (the
  `AddPlan`/`BuilderSitePlan` unions map directly to Swift `enum`s with
  associated values); the cross-thread cooldown registry maps to an `actor`
  or a `Sendable` type wrapping `os_unfair_lock`/`ManagedAtomic` rather than
  `SharedArrayBuffer` + `Atomics`, since Swift has no JS-style shared-buffer
  primitive across threads in one process.
- **Compose**: Mirrors SwiftUI's structural mapping — pure Kotlin `data
  class`/`sealed interface` planners, coroutines for the injected-I/O
  runner, and `kotlinx.atomicfu` or a `Mutex`-guarded `IntArray` in place of
  the `SharedArrayBuffer` registry for cross-thread/cross-coroutine cooldown
  state.
- **React/Web**: This is the source platform; no translation is needed. A
  browser-hosted port (as opposed to this Node-hosted one) would need a
  substitute for `SharedArrayBuffer` cross-THREAD sharing (a `Worker` plus
  `postMessage`, since browser `SharedArrayBuffer` requires cross-origin
  isolation headers this component's server context does not need).
- **AppKit/UIKit**: Same mapping as SwiftUI's controller-level equivalents;
  `URLSession` with `URLSessionConfiguration.timeoutIntervalForRequest`
  provides the `withTimeout`/`AbortSignal.timeout` equivalent, and
  `NSCache` (with an explicit last-write timestamp, since `NSCache` has no
  built-in TTL) can back the single-flight cache's storage half provided a
  separate in-flight-promise/continuation dictionary still de-duplicates
  concurrent misses.
- **WinUI 3**: `HttpClient` (with a per-call `CancellationTokenSource`
  driving a timeout, replacing `AbortSignal`/`withTimeout`) issues the
  provider requests; `System.Text.Json` replaces the `JSON.parse`/`res
  .json()` calls throughout the provider adapters; no file lives under
  `Windows.Storage` since no given source persists anything to disk;
  `Task`/`async`-`await` replaces the `Promise`-based `applySequentially`/
  `mapLimit` orchestration, with `System.Threading.Channels` or a plain
  `SemaphoreSlim` bounding `mapLimit`'s concurrency; the cross-thread
  cooldown registry maps to a shared `long[]` (or a small
  `MemoryMappedFile`) mutated only through `Interlocked.Exchange`/
  `Interlocked.CompareExchange`, the .NET equivalent of the source's
  `Atomics.store`/`Atomics.load` discipline; a port has no
  `ObservableCollection`/`INotifyPropertyChanged` counterpart to add here,
  since none of the given sources expose an observable collection — every
  result is a plain returned value or array.

