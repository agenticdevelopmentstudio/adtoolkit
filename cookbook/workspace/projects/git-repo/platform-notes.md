
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/GitRepo.swift`, a
  plain Foundation file with no import beyond `Foundation` and no dependency
  on SwiftUI, AppKit, or UIKit at all — the three types are UI-framework-free
  and port unchanged into any Swift target.
- **Compose**: Model `GitRepo` as a Kotlin `data class` with a `UUID`
  (`java.util.UUID`) `id`, `String path`, `String name`, `String? remote`,
  and `java.time.Instant firstSeen`/`lastSeen`/`lastOpened?`; Kotlin's
  synthesized `equals`/`hashCode` on a `data class` already produce the same
  structural (not identity-only) equality this file's synthesized
  `Equatable` produces, so no extra work is needed to preserve that
  behavior. `ScannedGitRepo` and `ProjectScanSummary` port the same way,
  each as its own `data class`; `URL(fileURLWithPath:).lastPathComponent`
  becomes `java.io.File(path).name` (or `Path.of(path).fileName`).
- **React/Web**: A browser has no filesystem, so `path`/`url` have no direct
  analogue; if this pattern is ported into a Node-hosted process, represent
  `GitRepo` as a plain object or a small class with the same seven fields, an
  `id: string` (a UUID string or `crypto.randomUUID()`), and derive
  `defaultName`/`leafName` with `path.basename(p)` instead of
  `URL(fileURLWithPath:).lastPathComponent`. `summaryText`'s formatting logic
  ports as a pure function taking a plain `{added, moved, removed, unchanged,
  skipped}` object.
- **AppKit / UIKit**: Identical to the SwiftUI note — nothing in this file
  is tied to a UI framework; it ports unchanged to either.
- **WinUI 3**: Port `GitRepo` as an immutable-`Id` C# `record` (or a class
  with a `readonly Guid Id`) with mutable `string Path`, `string Name`,
  `string? Remote`, `DateTimeOffset FirstSeen`, `LastSeen`, and
  `DateTimeOffset? LastOpened` — a C# `record`'s synthesized value equality
  already compares every property, matching this file's synthesized
  `Equatable` (including timestamps) with no extra code. Default `Id` to
  `Guid.NewGuid()` and `FirstSeen`/`LastSeen` to `DateTimeOffset.Now` in the
  constructor, mirroring `init`'s defaults. Port `url` as a computed
  `System.IO.DirectoryInfo`/`Uri` built from `Path`, and
  `defaultName(forPath:)`/`leafName` as
  `System.IO.Path.GetFileName(path.TrimEnd('\\', '/'))` — note that
  `Path.GetFileName` behaves differently from `URL.lastPathComponent` on a
  path ending in a separator, so a faithful port trims the trailing
  separator first. Port `ProjectScanSummary` as a small mutable class or
  `record struct` with five `int` properties and a computed `Found`/
  `SummaryText`, using `ObservableCollection`/`INotifyPropertyChanged` only
  if a bound UI needs to react to the counts changing — nothing in this
  file requires that on its own.

