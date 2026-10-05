
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/AIPluginKit/LocalInferenceGuard.swift`,
  alongside its collaborators `ModelFitPolicy.swift`,
  `LocalModelCatalog.swift`, and `SystemMemoryMonitor.swift`, and its
  consumer `DaemonAIChat.swift`/`DaemonProviderResolver.swift` (the source of
  `ProviderSettingsReader`). `LocalInferenceGuard` is declared as an `actor`,
  so its mutable state (`busy`, `waiters`) is serialized by the actor's own
  executor rather than by a manual lock; the mutex and deadline race are
  built from `CheckedContinuation` and `withThrowingTaskGroup`, with a
  post-acquire `Task.checkCancellation()` check, `defer`-guaranteed
  `release()` on every exit path, and a `CancellationError` thrown for both
  a cancelled parked waiter and a caller cancelled before/at acquire.
  `runExclusive<T: Sendable>` requires its `operation` closure to be
  `@Sendable` and `T` to conform to `Sendable`, since `operation` runs
  inside a `Task` racing the deadline-timer task; attempting
  `runExclusive { NSMutableString() }` (a non-`Sendable` return type) in a
  strict-concurrency build fails to compile. `waiterCount` carries no
  `public`/`private` modifier (Swift's default `internal`), so it functions
  as a test seam reachable only via `@testable import` without becoming
  part of the type's public API. It uses `os.Logger` for logging
  (subsystem `com.agentic-cookbook.AIPluginKit`, category
  `LocalInferenceGuard`, `privacy: .public` on the warn-tier message), and
  `DispatchSourceMemoryPressure` (via `SystemMemoryMonitor`) for live
  pressure. Nothing here is SwiftUI-specific — any host consumes
  `LocalInferenceGuard` identically.
- **Compose**: Kotlin has a ready FIFO-fair primitive
  (`kotlinx.coroutines.sync.Mutex`) to stand in for the hand-rolled
  continuation queue, and `withTimeoutOrNull`/`withTimeout` from
  kotlinx-coroutines in place of the manual `TaskGroup` deadline race.
  `ActivityManager.MemoryInfo`/`ComponentCallbacks2.onTrimMemory` is the
  Android analogue of `SystemMemoryMonitoring`'s latched pressure level; a
  plain `object`/singleton class stands in for `LocalInferenceGuard.shared`.
- **React/Web**: Neither Node.js nor the browser exposes an OS-level
  memory-pressure signal analogous to `DispatchSourceMemoryPressure`; a Node
  host can approximate available headroom with `os.totalmem()` /
  `process.memoryUsage()` but has no `.warning`/`.critical` latch to read. Use
  an async mutex library (e.g. `async-mutex`'s `Mutex`, which is FIFO by
  default) for the exclusive lock, `AbortController` plus `Promise.race`
  against a `setTimeout` for the deadline race in place of
  `withThrowingTaskGroup`, and `fetch` with `AbortSignal.timeout(5000)` for
  the model-size lookup analogous to `LocalModelCatalog.liveFetcher`.
- **AppKit / UIKit**: Identical to the SwiftUI note — this actor is
  UI-framework-agnostic; only the host application embedding `AIPluginKit`
  differs, never this contract.
- **WinUI 3**: Model `LocalInferenceGuard` as a plain C# class wrapping a
  `SemaphoreSlim(1, 1)` (FIFO-fair by default) in place of the hand-rolled
  `CheckedContinuation` waiter queue, exposing an `async Task<T>
  RunExclusiveAsync<T>(TimeSpan deadline, Func<Task<T>> operation)` method.
  Race the deadline with `Task.WhenAny(operationTask,
  Task.Delay(deadline, cts.Token))` and a `CancellationTokenSource` in place
  of `withThrowingTaskGroup`, cancelling the loser exactly as the source
  does. Represent `AIGuardError` as two distinct exception types (e.g.
  `AiGuardBlockedException` / `AiGuardDeferredException`), never a subtype or
  wrapper of whatever exception carries transport failures, so a `catch`
  block for the CLI-style fallback path structurally cannot also catch a
  guard refusal. Use `GlobalMemoryStatusEx` (via P/Invoke) or
  `Windows.System.MemoryManager.AppMemoryUsageLevel` for the RAM/pressure
  analogue of `SystemMemoryMonitoring`, and `HttpClient` with a 5-second
  `Timeout` for the model-size fetch analogous to
  `LocalModelCatalog.liveFetcher`.

