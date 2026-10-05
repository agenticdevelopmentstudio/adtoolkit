
- **SwiftUI**: The git client is Foundation-only and framework-agnostic,
  but its own documentation calls out a SwiftUI caller by name: a `.task`
  that drives the status verb and is torn down mid-flight is the reason
  the execution step rethrows a cancellation signal unchanged rather than
  wrapping it. A SwiftUI port keeps that contract by driving every verb
  from a cancellable task and never catching a cancellation signal as if
  it were one of the git client's own error outcomes.
- **AppKit / UIKit**: The nine source files (`GitBranch.swift`,
  `GitCaller.swift`, `GitClient.swift`, `GitClientConfiguration.swift`,
  `GitClientError.swift`, `GitCommandLog.swift`, `GitConfigEntry.swift`,
  `GitFileStatus.swift`, `GitStatus.swift`, `GitWorktree.swift`) live in
  the shared `AgenticToolkitCore` framework (`Core/Git/`) and import only
  `Foundation` and `OSLog` — no `AppKit`/`UIKit` dependency at all.
  `GitClient` is declared as a Swift `actor`, whose verbs each suspend at
  the `await SubprocessChannel.run` point, releasing the actor for the
  whole lifetime of the child process (**concurrent-calls-not-serialized**);
  its private `execute` method is the sole call site of
  `SubprocessChannel.run` in this component (**single-spawn-point**).
  `GitBranch`, `GitCaller`, `GitClientConfiguration`, `GitConfigEntry`,
  `GitFileStatus`, `GitStatus`, and `GitWorktree` each declare `Sendable`
  conformance to satisfy **value-types-thread-safe** across the actor's
  async boundary. `execute` checks
  `FileManager.default.isExecutableFile(atPath:)` before spawning
  (**executable-preflight**); its total catch chain maps
  `WallClockBudgetExceeded` to `GitClientError.timedOut` and every other
  error to `.launchFailed`, with a `CancellationError`-specific catch ahead
  of both that rethrows unchanged (**total-failure-mapping**,
  **cancellation-error-passthrough**). `GitCaller`'s `file` and `function`
  properties are captured via `#fileID`/`#function` default arguments
  evaluated in the calling context (**caller-capture-at-call-site**).
  `execute` decodes captured standard output as UTF-8 first, falling back
  to ISO Latin-1, never to `String(decoding:as:)`'s lossy-replacement
  decoding (**output-decode-fallback**).
  `GitClientConfiguration.fromSettings()` reads `UserSettings
  .gitExecutablePath`, `.gitStatusTimeoutSeconds`, and
  `.gitStatusIncludesSubmodules` (`UserSettings+Git.swift`).
  `GitCommandLog`'s subsystem/category come from its `Loggable`
  conformance's `makeLogger()`; arguments are logged at `.public` `OSLog`
  privacy after redaction, never through `OSLogPrivacy.private`, because
  that would collapse the whole interpolation for every verb rather than
  redacting the one argument position that needs it. An AppKit or UIKit
  caller consumes the same actor and the same four-case error outcome
  through ordinary `async`/`await`, with no framework-specific adaptation
  needed.
- **Compose (Kotlin/Android)**: The actor's bottleneck-for-accounting model
  maps to a Kotlin object exposing `suspend fun`s backed by
  `ProcessBuilder`/`Process`, run on `Dispatchers.IO`; `withTimeout` stands
  in for the wall-clock budget, a sealed class with the same four variants
  stands in for the git client's error outcome, and
  `kotlinx.coroutines.CancellationException` is the analog that MUST
  likewise be left to propagate unchanged rather than wrapped.
- **React/Web**: There is no browser-side equivalent of spawning a native
  git process; a web port MUST run the equivalent of this component in a
  Node.js backend (`child_process.spawn`/`execa`) behind an API the page
  calls, with an `AbortController`/`AbortSignal.timeout` standing in for
  the configured timeout and a discriminated union mirroring the four
  error-outcome cases returned as the API's error shape.
- **WinUI 3**: This is a process-spawning wrapper, not an HTTP client, so
  `HttpClient`/`System.Text.Json` do not apply. The port is
  `System.Diagnostics.Process` (`ProcessStartInfo` with
  `RedirectStandardOutput`/`RedirectStandardError` and an environment
  dictionary carrying `GIT_TERMINAL_PROMPT=0`) driven by `Task`/`async`-
  `await` in place of the actor — a single static class or service, never
  a `SemaphoreSlim(1)`, since serialized execution would contradict the
  concurrent-processes contract above. `CancellationTokenSource` with a
  `TimeSpan` timeout replaces the wall-clock budget and
  `OperationCanceledException` replaces the cancellation signal as the one
  type that MUST propagate unchanged. `Windows.Storage
  .ApplicationDataContainer` is the analog of the three settings
  `fromSettings()` reads. `ObservableCollection`/`INotifyPropertyChanged`
  have no direct analog here — this component has no bindable, mutable
  collection of its own — but would back a WinUI view model that exposes a
  status snapshot to XAML.

