
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific. It is a caseless `enum` with one static `migrate(from:to:markers:fileManager:)` returning an `Outcome` (`nothingToMigrate`, `migrated`, `alreadyMigrated`, `bothExist`, `migratedReplacingPlaceholder(asideAt:)`) and throwing `MigrationError.rollbackFailed(original:asideAt:)` or a `POSIXError`. Moves use `renamex_np` with `RENAME_EXCL`, which fails with `EEXIST` on an existing destination and `EXDEV` across volumes; a file system without it fails with `ENOTSUP`. An empty placeholder is removed with `rmdir`.
- **Compose**: On Android, `File.renameTo` within app-private storage is the atomic rename; check that the destination is absent first, because `renameTo` gives no exclusive-create guarantee on every file system.
- **React/Web**: Not applicable: a browser has no directory-rename primitive; storage moves are key copies, which this contract forbids.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic.
- **WinUI 3**: `MoveFileEx` without `MOVEFILE_REPLACE_EXISTING` and without `MOVEFILE_COPY_ALLOWED` gives the same exclusive, same-volume rename.

