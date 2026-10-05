
- **SwiftUI**: Expose a state binding (`Binding<Value>`) or an observable object; SwiftUI re-reads on change, so the explicit change callback is rarely needed.
- **Compose**: Use a `MutableState<Value>` or a `StateFlow`; collecting the flow replaces the change callback.
- **React/Web**: Use a store with a subscribe function (a signal, a Redux selector or `useSyncExternalStore`); notify on the next task turn to match the deferred delivery.
- **AppKit / UIKit (source)**: `SettingObserving` is a `@MainActor` protocol constrained to `AnyObject` with `value` and `onChange` members. `ClosureSettingObserver<Value>` implements the closure form with `init(get:set:onChange:)`; `UserSettingObserver` conforms through an extension. A write calls the setter, then schedules `DispatchQueue.main.async` and re-enters the main actor with `MainActor.assumeIsolated` before calling `onChange`. The main dispatch queue is used rather than `RunLoop.main` because run-loop-mode delivery stalls during event tracking. Views re-read the value inside the callback.
- **WinUI 3**: Implement as an interface with a `Value` property and a `ValueChanged` event; raise the event through `DispatcherQueue.TryEnqueue` on the UI thread so delivery follows the write, matching the deferred callback.

