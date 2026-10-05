
- **SwiftUI**: Not used; the service has no view layer.
- **Compose**: A service object over the persistence interface; refusals as a sealed class.
- **React/Web**: A module of async functions over a repository; refusals as typed `Error` subclasses.
- **AppKit / UIKit**: A Foundation-only enum namespace of static functions; refusals as `BillingError: LocalizedError`.
- **WinUI 3**: A static or injected service over an interface; refusals as exception types with a user-facing `Message`; wrap check-and-delete in a `SqliteTransaction`.

