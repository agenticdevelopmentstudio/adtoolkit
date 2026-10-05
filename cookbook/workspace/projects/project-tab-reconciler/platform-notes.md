
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectTabReconciler.swift`,
  which imports only `AgenticToolkitCore` and `Foundation` — no SwiftUI,
  AppKit, or UIKit dependency. A port needs its sibling value types
  alongside it: `TabRecord` and `Edge` from
  `macOS/UI/ViewControllers/ComposableTabs/LayoutNode.swift` and
  `macOS/UI/ViewControllers/MultiTabbedViewController/Edge.swift`, and
  `ProjectCheckout` from `macOS/Features/Projects/ProjectCheckout.swift`.
  Neither `ProjectTabReconciler` itself nor any of its four static
  functions (`plan`, `volumeIsMounted`, `arrangement`, `makeRecords`)
  declares an `actor` or `@MainActor` isolation, so every one of them is
  callable synchronously from any concurrency domain. Its `Plan` and
  `TabRecord` types both declare no explicit `Sendable` conformance, so
  neither type should be assumed safe to carry across an actor or `Task`
  boundary without explicit synchronization; `ProjectCheckout`, `UUID`,
  and `LayoutNode` — the other types this file's public signatures
  traffic in — are `Sendable`. The `existsOnDisk` and `volumeIsMounted`
  closure parameters of `plan(...)` are plain function values with no
  `@Sendable` annotation, so nothing in this file's own signature obliges
  a caller-supplied closure to be safe to invoke from a different
  concurrency domain than the one that constructed it.
- **Compose**: Model `plan`, `volumeIsMounted`, `arrangement`, and
  `makeRecords` as top-level functions or methods on a Kotlin `object` with
  no instance state. Port `URL` to `java.nio.file.Path`, the `Set<URL>`
  lookups to `mutableSetOf<Path>()`, and `resolvingSymlinksInPath()` to
  `Path.toRealPath()`. `existsOnDisk` becomes `(Path) -> Boolean` backed by
  `Files.exists(path)`; `volumeIsMounted` has no direct Android equivalent —
  the closest analog is `Environment.getExternalStorageState(file)` or
  `StorageManager.getStorageVolume(file)` reporting whether removable media
  is currently mounted, walked up the same way `deepestExistingAncestor`
  does.
- **React/Web**: Port `plan`, `arrangement`, and `makeRecords` as pure
  functions over plain arrays, a `Set`, and a `Map`, taking a path `string`
  in place of `URL`; `existsOnDisk` maps to `fs.existsSync(path)`. A browser
  or Electron renderer has no concept of a removable-volume mount point to
  match `volumeIsMounted` against, so a faithful port either restricts to a
  Node/Electron main-process context where `fs.statfs`-style mount
  inspection is available, or documents that the unmounted-volume protection
  this file provides has no equivalent and every gone directory is treated
  as deletable.
- **AppKit / UIKit**: Identical to the SwiftUI note — nothing in this file is
  tied to a UI framework, so it ports unchanged to either. An iOS host would
  still need its own `existsOnDisk` and `volumeIsMounted` that respect the
  App Sandbox rather than calling `FileManager`/`resourceValues` against an
  arbitrary path, since iOS has no user-visible `/Volumes` mount point to
  walk up to.
- **WinUI 3**: Port `plan`, `volumeIsMounted`, `arrangement`, and
  `makeRecords` as static methods on a static class, taking
  `IReadOnlyList<TabRecord>`, `IReadOnlyList<ProjectCheckout>`, and a
  `Func<string, bool>` in place of each closure parameter — no `Task`/`async`
  is needed anywhere in this port, matching the source's fully synchronous
  signatures. Build the directory set with `HashSet<string>` keyed on a
  normalized, case-preserving full path, and use
  `System.IO.Directory.Exists`/`File.Exists` for `existsOnDisk`. Port
  `resolvingSymlinksInPath()` with `FileSystemInfo.ResolveLinkTarget(true)`
  (.NET 6+) rather than `Windows.Storage`, since this is ordinary local-disk
  access, not packaged-app storage. Port `volumeIsMounted` by walking
  `Directory.GetParent(...)` until a directory exists, exactly like
  `deepestExistingAncestor`, then comparing `new DriveInfo(Path.GetPathRoot(...))`
  for both sides and checking `DriveInfo.IsReady` in place of the `/Volumes`
  special case. Port `TabRecord` and `ProjectCheckout` as C# records; because
  `TabRecord`'s `edge`, `title`, `root`, `focusedNodeID`, and
  `workingDirectory` are mutable (`var`) in the source, decide explicitly
  whether the port keeps them mutable or moves to `with`-expression-based
  immutability, since C# has no `Sendable` to make that choice visible in
  the type system the way the source's absence of `Sendable` on `TabRecord`
  does. Port `Plan` as a record with `Keep`, `Add`, and `Drop` collection
  properties and an `IsUnchanged` computed property, and treat it, like the
  source, as not inherently safe to hand across threads without the
  caller's own synchronization.

