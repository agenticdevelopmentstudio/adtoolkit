
- **SwiftUI**: Not used; the type has no view layer.
- **Compose**: A suspending read of a preferences `DataStore` snapshot.
- **React/Web**: A function over a settings API returning a frozen object; wrap writes in one database transaction.
- **AppKit / UIKit**: Foundation-only enum namespace over the `BillingPersistence` protocol: `database.setting(for:)`, `setSetting`, `transaction`.
- **WinUI 3**: A service over `ApplicationData` or SQLite with `IDbTransaction`; read once per pass and pass the immutable record onward.

