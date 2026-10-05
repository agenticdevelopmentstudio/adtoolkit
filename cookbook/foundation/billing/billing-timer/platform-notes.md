
- **SwiftUI**: Not used; the service has no view layer.
- **Compose**: A suspend-free service over the persistence interface; run `start` inside `withTransaction`.
- **React/Web**: A service over an async repository; do the close-then-insert in one transaction.
- **AppKit / UIKit**: A Foundation-only enum namespace; `TimeZone.current.identifier` for the zone and `UUID().uuidString` for the id.
- **WinUI 3**: A static or injected service using `Guid.NewGuid()` and `TimeZoneInfo.Local.Id` (IANA id via `TimeZoneInfo.Local.HasIanaId` or a converter); wrap close-and-insert in one `SqliteTransaction`.

