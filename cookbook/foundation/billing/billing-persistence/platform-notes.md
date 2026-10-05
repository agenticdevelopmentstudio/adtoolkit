
- **SwiftUI**: Not used; the contract has no view layer.
- **Compose**: An interface implemented over Room or SQLDelight, with `withTransaction`.
- **React/Web**: A repository interface over IndexedDB or a server API; map `transaction` to one atomic batch.
- **AppKit / UIKit**: A Swift protocol conformed to by the host's SQLite database manager; the type is not `Sendable`, so callers keep it in their own isolation.
- **WinUI 3**: An interface implemented over SQLite (`Microsoft.Data.Sqlite`) with `SqliteTransaction`; implement `transaction` with `BeginTransaction`/`Commit`/`Rollback`.

