
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; the write uses `Data.write(to:options: .atomic)` and the default URL is under `applicationSupportDirectory`.
- **Compose**: Store the stamp in `filesDir` (or a DataStore key) and compare the app's `versionName`; write with `AtomicFile`.
- **React/Web**: Use a `localStorage` key for the stamp and compare against the build's version constant; there is no file, so atomicity is free.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Write the stamp to `ApplicationData.Current.LocalFolder` using `FileIO.WriteTextAsync`, compare against `Package.Current.Id.Version` formatted as a string, and treat any `FileNotFoundException` as needs-setup.

