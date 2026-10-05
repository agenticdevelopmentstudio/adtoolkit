
- **SwiftUI**: Source: `packages/apple/AgenticToolkit/Core/FileSystem/
  FileSystemService.swift`, `Core/FileSystem/FileSystemServicing.swift`, and
  `Core/FileSystem/FileSignature.swift`. The type is plain `Foundation` with
  no SwiftUI dependency; a SwiftUI-hosted caller awaits one of the seven
  `async throws` operations from a `Task` and renders the returned value or
  caught `FileSystemServiceError` into its own `@State`/`@Observable` view
  state — `FileSystemService` itself holds none, and `AgenticToolkitCore`,
  the framework target that builds it, is configured `platform: macOS` in
  `packages/apple/AgenticToolkit/project.yml` today.
- **Compose**: On Kotlin/Android, port to a class exposing seven `suspend
  fun` equivalents (`readFile`, `readDirectory`, `stat`, `writeFile`,
  `createDirectory`, `delete`, `rename`), each running its `java.io.File`/
  `java.nio.file` work inside `withContext(Dispatchers.IO)` rather than the
  default coroutine dispatcher — Android's IO dispatcher is the analogue of
  this component's dedicated serial `DispatchQueue`, though it is a shared
  thread pool rather than one queue per instance, so a port that wants
  `calls-serialize-on-the-queue`'s ordering guarantee for one logical
  instance needs its own `Mutex` or single-threaded dispatcher rather than
  relying on `Dispatchers.IO` alone. Use `java.nio.file.Files.move` with
  `StandardCopyOption.ATOMIC_MOVE` where the target filesystem supports it
  for the `rename` port, and fall back to the same move-remove-move sequence
  this source uses when it does not, since `ATOMIC_MOVE` throws rather than
  completing when the underlying filesystem cannot guarantee it. Port the
  `FileType` bitmask as a Kotlin value class or `Int` constants with the same
  raw values (1, 2, 64) so a union like 65/66 round-trips identically for any
  caller comparing raw values across platforms.
- **React/Web**: There is no direct file-system access from a browser
  context; where this runs inside an Electron-style host with Node's `fs`
  module available, port to seven `async function`s returning `Promise`s,
  using `fs.promises.readFile`, `fs.promises.readdir` with
  `withFileTypes: true`, `fs.promises.lstat` for the non-following `stat`
  port (Node's `lstat` mirrors this component's `stat-does-not-follow-
  terminal-link` requirement directly, while `fs.promises.stat` would follow
  the link and need to be avoided here), `fs.promises.writeFile`,
  `fs.promises.mkdir` with `{ recursive: true }`, `fs.promises.rm`, and
  `fs.promises.rename` for the non-conflicting move, falling back to the
  same remove-then-rename-again sequence this source uses when the
  destination is occupied and `overwrite` is `true`, since Node's `rename`
  fails outright on a non-empty directory destination the same way
  `rename(2)` does. Route deletions through Electron's `shell.trashItem`
  when the `useTrash` port needs it, and treat any `errno` on the resulting
  `NodeJS.ErrnoException` (`ENOENT`, `EEXIST`, `EISDIR`, `ENOTDIR`,
  `ENOTEMPTY`, `EACCES`/`EPERM`) as the direct analogue of this component's
  POSIX-code classification (`error-classification-posix-first`).
- **AppKit / UIKit**: This recipe is extracted directly from Foundation,
  callable identically from an AppKit-hosted (macOS) or UIKit-hosted (iOS)
  caller; since `AgenticToolkitCore` is configured `platform: macOS` today,
  an iOS caller would first need the type made available to an iOS target,
  but the type itself needs no AppKit/UIKit-specific change to run there.
  The file system service is `FileSystemService` (`FileSystemService.swift`),
  declared as a Swift `actor` so its stored `queue` property and its seven
  operations are safe to call concurrently from any thread or `Task` with no
  additional synchronization at the call site (`concurrent-call-safety`).
  Each operation runs its blocking `FileManager` work on one private serial
  `DispatchQueue` (`qos: .userInitiated`) created once at `init()`, bridged
  back into the caller's `async` context via `withCheckedThrowingContinuation`
  in `perform(_:)`; every operation constructs its own fresh `FileManager()`
  inside its queued closure rather than capturing a shared instance, because
  `FileManager` is not `Sendable` (`fresh-file-manager-per-call`). The
  substitution interface is the `Sendable` protocol `FileSystemServicing`
  (`FileSystemServicing.swift`), which `FileSystemService` satisfies via an
  empty `extension` adding no code of its own
  (`servicing-conformance-is-free`). The file signature is the `Sendable`,
  `Equatable` `struct FileSignature` (`FileSignature.swift`) with
  `size: Int` and `modified: Date`; its `init?(of:)` derives both from
  `FileManager.default.attributesOfItem(atPath:)` rather than
  `url.resourceValues(forKeys:)` (`file-signature-stat-source`). The
  file-system error outcome is the `Error, LocalizedError` enum
  `FileSystemServiceError` (`FileSystemService.swift`), neither `Equatable`
  nor `Sendable` because its `noPermissions` case carries an `any Error`
  underlying cause; its cases are `fileNotFound`, `fileExists`,
  `fileIsADirectory`, `fileNotADirectory`, `directoryNotEmpty`,
  `noPermissions`, and the per-operation fallbacks `readFailed`,
  `writeFailed`, `statFailed`, `readDirectoryFailed`, `deleteFailed`,
  `renameFailed`, `createDirectoryFailed`; `errorDescription` returns one
  hardcoded English sentence per case via string interpolation, with no
  `NSLocalizedString` or `.strings` lookup. Classification
  (`distinguished(_:path:)`) checks a thrown error's POSIX code first via
  `posixCode(in:depth:)`, which walks a chain of `NSUnderlyingErrorKey`
  errors up to 4 levels, then falls back to the error's `CocoaError` code.
  The `FileType` bitmask uses raw values 1 (file), 2 (directory), 64
  (`symbolicLink`), with a link's own type unioned with its resolved
  target's bit where determinable (65 for a link to a file, 66 for a link
  to a directory) and `FileType.unknown` for a child whose type cannot be
  determined. `writeFile` writes via `Data.write(to:)` in place, never a
  temp-file-and-rename; `createDirectory` uses
  `FileManager.createDirectory(atPath:withIntermediateDirectories: true)`;
  `delete` uses `FileManager.trashItem(at:resultingItemURL: nil)` when
  `useTrash` is `true` and `FileManager.removeItem(at:)` otherwise;
  `rename` uses one `FileManager.moveItem(at:to:)` call, falling back to
  `FileManager.removeItem` then a retried `moveItem` when the destination is
  occupied and `overwrite` is `true`.
- **WinUI 3**: Port to a class exposing seven `async Task<T>` (or
  synchronous, for the parts that do not need to be awaited) equivalents,
  offloading each one's blocking work onto `Task.Run` as the counterpart to
  this component's dedicated `DispatchQueue` — bearing in mind, as with the
  sibling `VSIXInstaller` recipe's own WinUI note, that .NET's thread pool
  growing to accommodate blocking work makes the concern milder rather than
  absent. Use `System.IO.File`/`System.IO.Directory` members for `readFile`
  (`File.ReadAllBytesAsync`), `readDirectory`
  (`Directory.EnumerateFileSystemEntries` plus a per-entry `FileAttributes`
  check for the `FileType` bitmask port), and `writeFile`
  (`File.WriteAllBytesAsync`). `stat`'s non-following requirement
  (`stat-does-not-follow-terminal-link`) needs care on Windows: a plain
  `FileInfo`/`DirectoryInfo` follows a reparse point (the Windows analogue of
  a symbolic link) by default, so a faithful port must pass
  `FileOptions` or use `File.GetAttributes` with the `ReparsePoint` flag
  checked explicitly to answer the link's own attributes rather than its
  target's, mirroring what `lstat`-family calls give `stat(atPath:)` here.
  For `rename`'s overwrite sequence, use `Directory.Move`/`File.Move` for the
  non-conflicting path and the same move-remove-move-again sequence for the
  conflicting one, since `File.Move`/`Directory.Move` throw rather than
  atomically replace an existing destination — matching why this source
  needs the same three-step sequence rather than a single API call. Windows'
  own Recycle Bin has no first-party .NET API as of this writing, so a
  `useTrash` port typically needs `Microsoft.WindowsAPICodePack.Shell` or an
  equivalent shell-interop package rather than a framework type.

