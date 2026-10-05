
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectReconciler.swift`,
  a plain Foundation file (`import Foundation` only) with no dependency on
  SwiftUI, AppKit, or UIKit; it ports unchanged into any Swift target that
  also has `GitRepo.swift`. The `Plan` value conforms to `Sendable`, and the
  type declares no `actor` or `@MainActor` isolation on itself or on any of
  its three static functions, matching the type's own doc comment, which
  states it is "Pure and `nonisolated`" so it can be tested without a
  database, a filesystem, or a main actor. The `isStillARepository` closure
  parameter's type carries no `@Sendable` annotation — unlike
  `GitRepoScanner`'s `isCancelled` and `onProgress` parameters — so nothing
  in this file's own signature obliges a caller-supplied closure to be safe
  to invoke from a different concurrency domain than the one that
  constructed it; the default `ProjectReconciler.repositoryExists` captures
  nothing and is safe to call from anywhere.
- **Compose**: Model `plan` as a top-level function or a Kotlin `object`
  with no instance state, taking `List<GitRepo>`, `List<ScannedGitRepo>`,
  and an `Instant` in place of `Date`. Build the path lookup with a
  `mutableMapOf<String, GitRepo>()`, the seen-ids and claimed-paths sets
  with `mutableSetOf()`, and port the LIFO-free, single-pass loops directly;
  `uniqueName` becomes a function over `java.io.File(path).toPath().nameCount`
  or a manual split on `File.separator`.
- **React/Web**: Port `plan` as a pure function over plain arrays and a
  `Map`/`Set`, taking `number` (epoch millis) in place of `Date`; there is
  no filesystem distinction to preserve since a Node-hosted port of
  `repositoryExists` would use `fs.existsSync(path.join(p, ".git"))`, matching
  the "existence is the whole test" contract exactly. `uniqueName` ports as
  a function over `path.sep`-split segments with the same escalating-suffix
  loop.
- **AppKit / UIKit**: Identical to the SwiftUI note — nothing in this file
  is tied to a UI framework; it ports unchanged to either. An iOS host would
  still need its own, separately-contracted `isStillARepository` that
  respects the App Sandbox rather than calling `FileManager` against an
  arbitrary path.
- **WinUI 3**: Port `plan` as a static method on a static class, taking
  `IReadOnlyList<GitRepo>`, `IReadOnlyList<ScannedGitRepo>`, a
  `DateTimeOffset`, and a `Func<string, bool>` in place of the closure
  parameter. Build the path lookup with a `Dictionary<string, GitRepo>`, the
  seen-ids and claimed-paths sets with `HashSet<Guid>`/`HashSet<string>`, and
  keep the same three-pass order (exact match, then moves, then inserts,
  then whatever remains is deleted) rather than reordering it into LINQ
  joins, since the ordering itself (moves claiming a path before inserts
  run) is part of the contract. Port `repositoryExists` with
  `System.IO.Directory.Exists`/`File.Exists` against `System.IO.Path.Combine(path, ".git")`
  rather than `Windows.Storage`, since this is ordinary local-disk access,
  not packaged-app storage. Port `uniqueName` with
  `System.IO.Path.GetFileName`/manual splitting on `System.IO.Path.DirectorySeparatorChar`
  and the same escalating-suffix loop; no `Task`/`async` is needed anywhere
  in this port, since every operation here is synchronous in the source.

