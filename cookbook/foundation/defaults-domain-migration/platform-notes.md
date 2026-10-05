
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with one static function using `UserDefaults.persistentDomain(forName:)` and `setPersistentDomain(_:forName:)`.
- **Compose**: Android has no bundle-identifier-keyed domain; the analog is migrating a `SharedPreferences` file or DataStore after a package rename by copying all entries once, guarded by the new store being empty.
- **React/Web**: Browser storage is keyed by origin; after an origin change copy `localStorage` entries from the old origin through a cross-origin message, only while the new origin's storage is empty.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Packaged apps keep settings in `ApplicationData.Current.LocalSettings` under the package family name; after a package-identity change, copy the old container's values once, guarded by the new `LocalSettings.Values` being empty, and leave the old data in place.

