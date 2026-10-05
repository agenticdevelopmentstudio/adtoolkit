
- **SwiftUI**: The sources are
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/FileBrowser/Model/Git/GitStatusProvider.swift`
  and `GitFileStatus+Color.swift` in the same directory, alongside their
  collaborators `GitClient.swift`, `GitStatus.swift`, `GitFileStatus.swift`,
  and `GitClientError.swift` (all under `Core/Git`). Both files are plain
  Swift with no SwiftUI-specific API beyond the color extension's
  `SwiftUI.Color` property; see the AppKit/UIKit note below for the
  concurrency, locking, and logging mechanisms the shipped implementation
  actually uses.
- **Compose**: Jetpack Compose has one `androidx.compose.ui.graphics.Color`
  type, so the `color`/`nsColor` duplication has no reason to exist on this
  platform — port both into a single `val GitFileStatus.color: Color`
  extension. For the provider, use a `kotlinx.coroutines.sync.Mutex` (or a
  plain `synchronized` block) to guard a data class equivalent to `State`, a
  `MutableStateFlow`/`SharedFlow<GitStatusRefreshResult>` or a listener
  `MutableList` under that lock in place of the UUID-keyed observer map, and
  `Dispatchers.Main.immediate` for delivery. Kotlin listeners are typically
  removed explicitly rather than via `deinit`, so a faithful port should keep
  an explicit disposable/token type returned from `observe` to preserve the
  "cannot forget to unregister" guarantee.
- **React/Web**: Model the provider as a small class exposing
  `subscribe(observer)` that returns an unsubscribe function — the returned
  function stands in for `GitStatusObservation` — backed by a `Set` of
  callbacks; no extra locking is needed since JavaScript has no preemptive
  threads. A browser cannot spawn a process at all, so git status can only
  be asked from a Node-hosted process (`child_process.execFile` running
  `git`); a browser-only port of this pattern has no `GitClient` equivalent
  to call. Use CSS custom properties or a token map (a `modified` key mapped
  to an orange value) in place of `Color`/`NSColor`.
- **AppKit / UIKit**: The provider uses `OSAllocatedUnfairLock` to guard its
  mutable state (`observers`, `isRunning`, `isQueued`), an unstructured
  `Task` plus `MainActor.run` for the fetch-then-deliver cycle, and
  `os.Logger` via the shared `Loggable` protocol for logging, with
  `Bundle.main.bundleIdentifier` (falling back to the literal string
  `"nil"` if unset) as the log subsystem. The color extension is plain
  computed properties: `color: SwiftUI.Color` for the primary mapping and
  `nsColor: AppKit.NSColor` for the secondary one; the exact hue constants
  are `.systemOrange`, `.systemGreen` (added and untracked), `.systemRed`,
  `.systemBlue` (renamed and copied), `.systemPurple`, and `.systemGray`,
  paired with SwiftUI's `.orange`, `.green`, `.red`, `.blue`, `.purple`, and
  `.gray`. The error-level log message is built from
  `GitClientError.logDescription` when the failure originates from the git
  client, or from the error's type name otherwise — explicitly never from
  `errorDescription` or `error.localizedDescription`, since
  `errorDescription` interpolates the command-failure case's raw
  `standardError` text. The observation token's unregistration closure
  captures the provider weakly and fires from the token's own `deinit`, so a
  consumer cannot forget to unregister and an outstanding token cannot keep
  the provider alive. Nothing here is tied to AppKit specifically beyond the
  `NSColor` type; a UIKit (iOS) port needs only `UIColor`, one type, which
  removes the duplication the same way Compose does, and the provider itself
  ports unchanged.
- **WinUI 3**: Port `GitStatusProvider` as a plain C# class holding a lock
  object (or `System.Threading.Lock`) guarding a private record equivalent
  to `State` — a `Dictionary<Guid, Action<GitStatusRefreshResult>>` for
  observers, plus `isRunning`/`isQueued` booleans — and expose
  `IDisposable Observe(Action<GitStatusRefreshResult> observer)` returning a
  disposable whose `Dispose()` removes the entry, the direct analogue of a
  `deinit`-triggered token. Marshal delivery to the UI thread with
  `DispatcherQueue.TryEnqueue` in place of `MainActor.run`. Represent
  `GitStatusRefreshResult` as a small discriminated union or a two-case
  class hierarchy. Use `Microsoft.UI.Colors`/`Windows.UI.Color` for the
  status-to-color mapping — again one color type, no `NSColor`-style
  duplicate needed. Log with `Microsoft.Extensions.Logging`'s `ILogger`,
  taking care that whatever formats the failure message never interpolates
  the git subprocess's raw standard-error text, mirroring `logDescription`'s
  omission.

