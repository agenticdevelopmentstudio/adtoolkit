
- **React/Web**: Source is a custom React hook (`useActivityTtl`) using `useState` for in-memory state, `useEffect` for one-shot hydration from `localStorage`, and `useCallback` to memoize `setTtl`. The `"use client"` directive indicates it is a client component in a Next.js App Router context.
- **SwiftUI**: Equivalent to a `@State` property or `@EnvironmentObject` that reads and writes to `UserDefaults` (macOS) or `NSUserDefaults` (iOS) with a hardcoded key. Hydration would occur during `onAppear`.
- **Compose**: Equivalent to a `ViewModel` with a `MutableState<Int?>` or a custom `Preference` data store that persists to `SharedPreferences`.
- **AppKit / UIKit**: Equivalent to a view controller property backed by `UserDefaults` with custom getters/setters for persistence and recovery.
- **WinUI 3**: Equivalent to a `ViewModel` (INotifyPropertyChanged) with a private backing field that reads/writes to `Windows.Storage.ApplicationData.Current.LocalSettings` or `IsolatedStorageSettings`. Loading from settings MUST validate against the allowed set (the setter, like `setTtl`, does not) and gracefully handle deserialization errors. Multi-user / profile-switching behavior differs: Windows Settings are per-user per-app; the equivalent of `localStorage.clear()` on logout is the app's responsibility.

