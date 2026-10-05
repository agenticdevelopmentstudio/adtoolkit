
- **SwiftUI**: No SwiftUI in the source. A SwiftUI macOS app gets frame
  persistence from `Window`/`WindowGroup` scene autosave and
  `defaultPosition`/`defaultSize`, and document recents from
  `DocumentGroup`; launch restore of utility windows still needs a
  coordinator like this one calling `openWindow(id:)` for IDs saved
  visible, with `@AppStorage` or `SceneStorage` in place of
  `WindowStateStorage`.
- **Compose**: Compose for Android has no multi-window desktop model; a
  Compose Desktop port starts from `rememberWindowState` and
  `WindowPosition`, persists with DataStore plus `kotlinx.serialization`,
  keeps the registry as a `Map<String, WeakReference<…>>` confined to
  `Dispatchers.Main`, and replaces the termination latch with an
  `ApplicationScope` exit hook. The namespace hash maps to
  `MessageDigest.getInstance("SHA-256")`.
- **React/Web**: Browsers own window placement; an Electron port starts
  from `BrowserWindow.getBounds`/`setBounds`, `app.on('before-quit')` for
  the termination latch, `app.addRecentDocument` for recents,
  `electron-store` or `localStorage` with `JSON.stringify` for storage,
  `webContents.capturePage()` for screenshots, and Node
  `crypto.createHash('sha256')` for the namespace.
- **AppKit / UIKit**: Source files: `WindowManager.swift` (Combine sink on
  `UserSettings.recentWindowsCount`, mirrored into the `NSRecentDocumentsLimit`
  user default; `NSQuitAlwaysKeepsWindows` read for the system reopen
  default; selector-based `NotificationCenter` observer for
  `willTerminateNotification`, `os.Logger`, `NSDocumentController` recents
  and reopen), `WindowRegistry.swift` (weak boxes over
  `SingleWindowController`), `WindowStateStorage.swift`,
  `SettingsStoreWindowStateStorage.swift` (`StorableSetting` keys through
  `SettingsStore`), `UserDefaultsWindowStateStorage.swift`
  (`JSONEncoder`/`JSONDecoder` over `UserDefaults.standard`,
  `dictionaryRepresentation()` scan), `WindowStateNamespace.swift`
  (`OSAllocatedUnfairLock`, CryptoKit `SHA256`), `WindowScreenshot.swift`
  (`dlsym` of `CGWindowListCreateImage`, `NSBitmapImageRep` PNG). UIKit has
  no free-floating windows; scene restoration
  (`stateRestorationActivity`, `UISceneSession.userInfo`) replaces frame
  and visibility persistence.
- **WinUI 3**: Start from `Microsoft.UI.Windowing.AppWindow` (`Position`,
  `Size`, `MoveAndResize`, `Show`/`Hide`, `IsVisible`, `Closing` event) with
  `DisplayArea` for screen bounds. Keep the manager and registry on the UI
  thread via `DispatcherQueue`; hold controllers in a
  `Dictionary<string, WeakReference<T>>` and expose `VisibleIds`/
  `HasVisibleWindow` through `INotifyPropertyChanged` if bound. Persist
  `PersistedWindowState` with `System.Text.Json` into
  `Windows.Storage.ApplicationData.Current.LocalSettings` (the 8 KB
  per-value limit favors one key per window, as the source already does)
  and store visibility as a native `bool` value so absence stays
  distinguishable via `ContainsKey`. Replace `willTerminateNotification`
  with `Application.Current` exit handling or `AppWindow.Closing` plus an
  app-level shutdown flag; replace the Combine settings sink with a
  `PropertyChanged` handler. Document recents map to
  `Windows.Storage.AccessCache.StorageApplicationPermissions.MostRecentlyUsedList`
  (with `MaximumItemsAllowed` in place of `NSRecentDocumentsLimit`) and
  jump lists (`Windows.UI.StartScreen.JumpList`). The namespace hash is
  `System.Security.Cryptography.SHA256.HashData`, guarded with `lock`.
  Own-window screenshots use `Windows.Graphics.Capture` with
  `GraphicsCaptureItem.TryCreateFromWindowId` or `RenderTargetBitmap` for
  XAML content, encoded with `BitmapEncoder.PngEncoderId`. Windows
  coordinates are top-left origin, unlike AppKit.

