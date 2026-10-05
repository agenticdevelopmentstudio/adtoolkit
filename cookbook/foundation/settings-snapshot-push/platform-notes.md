
- **SwiftUI**: The source file imports `Foundation` and the logging framework; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. The push is `@MainActor`, observers are the settings-store observer type, and the retry engine is `Task`-based with `Task.sleep`.
- **Compose**: Use a `CoroutineScope` on the main dispatcher, a `Job` for the retry, and `flow.collect` on each setting to trigger `push()`; supersession is `job.cancel()` before launching.
- **React/Web**: A class with an `AbortController` per push: abort the previous controller before starting, check `signal.aborted` after each `await sleep(backoff)`, and listen to the transport's `online` or reconnect event to re-push.
- **AppKit / UIKit**: Identical to the SwiftUI note: the observers in the AppKit use are `UserSettingObserver` instances that defer to the next main-queue turn, and the reconnect registrar comes from the XPC connection wrapper.
- **WinUI 3**: Keep the push on the UI `DispatcherQueue`; observe settings via `INotifyPropertyChanged`, send through `NamedPipeClientStream` or an AppService connection, supersede with a `CancellationTokenSource` per push, and use `Task.Delay` for each backoff.

