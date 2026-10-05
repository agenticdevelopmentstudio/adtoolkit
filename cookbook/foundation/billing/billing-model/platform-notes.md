
- **SwiftUI**: A view observes the change signal (for example through an `ObservableObject` bridge); the model itself imports no SwiftUI.
- **Compose**: A `ViewModel` exposing `StateFlow`s with a polling coroutine; `async` reads via `async`/`await`.
- **React/Web**: A store (for example a reducer or a signal-based class) with a polling timer; use `Promise.all` for the concurrent reads.
- **AppKit / UIKit**: A `@MainActor final class` publishing through a Combine `PassthroughSubject<Void, Never>`; reads use `async let`; the poll is a `PeriodicRefresher`.
- **WinUI 3**: A class implementing `INotifyPropertyChanged` with `ObservableCollection` lists; poll with `PeriodicTimer` and read concurrently with `Task.WhenAll`; marshal changes through `DispatcherQueue`.

