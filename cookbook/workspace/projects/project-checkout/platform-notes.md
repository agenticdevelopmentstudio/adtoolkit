
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectCheckout.swift`,
  using only Foundation's `URL` (`resolvingSymlinksInPath()`,
  `lastPathComponent`, `path`) and the sibling type `GitWorktree` from
  `packages/apple/AgenticToolkit/Core/Git/GitWorktree.swift`; nothing here is
  SwiftUI-specific — the type has no view and no observable state, and is
  used elsewhere purely as a `Hashable`/`Sendable` identity for tab groups.
  The `Sendable` conformance, together with every stored property being
  declared with `let` (immutable) and each of `URL`, `String?`, and `Bool`
  themselves being `Sendable`, is the mechanism behind
  value-type-concurrency-safety — nothing about it depends on `@MainActor`
  or any other isolation annotation.
- **Compose**: Represent as a Kotlin `data class ProjectCheckout(val
  directory: File, val branch: String?, val isMain: Boolean)`, resolving
  `directory` in a secondary constructor or factory function with
  `File.canonicalFile`, the closest Kotlin/JVM equivalent of
  `resolvingSymlinksInPath()` in that it both resolves symlinks and
  normalizes `.`/`..` segments in one call. A Kotlin `data class` derives
  `equals`/`hashCode` over every constructor property automatically, which
  matches `hashable-includes-all-fields` without extra code. Compute
  `identifier` with the identical djb2 loop over
  `directory.path.toByteArray(Charsets.UTF_8)`, formatted with
  `java.lang.Long.toHexString`.
- **React/Web**: A browser has no filesystem, symlink, or worktree concept;
  a faithful port only exists in a Node-hosted process. Represent
  `ProjectCheckout` as a small immutable object (`{ directory: string;
  branch: string | null; isMain: boolean }`), resolve `directory` with
  `fs.realpathSync`, Node's equivalent of `resolvingSymlinksInPath()`, and
  compute `identifier` with the same djb2 loop over
  `Buffer.from(directory, "utf8")`, converting the running hash to a hex
  string. Because JavaScript object identity is reference-based, port
  `hashable-includes-all-fields` explicitly — a value-equality helper, or a
  `Map` keyed on a composite string of `directory`, `branch`, and `isMain`
  — rather than relying on `===`.
- **AppKit / UIKit**: Identical to the SwiftUI note — the type is
  UI-framework-independent Foundation code. An AppKit consumer uses it
  exactly as the macOS project controller does today, as `Set` membership
  and dictionary keys mapping checkouts to open tab groups; an iOS port has
  no analogous "worktree" concept unless a UIKit-based checkout picker is
  built on top of it separately.
- **WinUI 3**: Port as a C# `readonly record struct ProjectCheckout(string
  Directory, string? Branch, bool IsMain)`; a `record struct` synthesizes
  `Equals`/`GetHashCode` over all three properties automatically, matching
  `hashable-includes-all-fields` with no extra code. There is no single
  .NET call that both resolves a symlink and normalizes `.`/`..` segments
  the way `resolvingSymlinksInPath()` does, so chain
  `System.IO.Path.GetFullPath` (normalization) with
  `new DirectoryInfo(path).ResolveLinkTarget(returnFinalTarget: true)`
  (symlink resolution) in the constructor. Compute `Identifier` as a
  read-only property running the same djb2 loop over
  `System.Text.Encoding.UTF8.GetBytes(Directory)`, formatted with
  `.ToString("x")`. Nothing here touches `Windows.Storage` (this is not
  packaged-app storage) or `Task`/`async` (nothing here is asynchronous or
  networked).

