
- **SwiftUI**: Settings are bound to the pane through the holder's `UserSetting` values; no SwiftUI types are used by the holder.
- **Compose**: A `DataStore`-backed preference per setting, exposed as `Flow`.
- **React/Web**: A typed wrapper over a settings store (for example `localStorage` or a server-synced table) with change notification.
- **AppKit / UIKit**: A `@MainActor final class` whose properties are generic `UserSetting<T>` values; AppKit panes bind to them.
- **WinUI 3**: `ApplicationData.Current.LocalSettings` values behind a class implementing `INotifyPropertyChanged`; marshal writes to the UI thread through `DispatcherQueue`.

