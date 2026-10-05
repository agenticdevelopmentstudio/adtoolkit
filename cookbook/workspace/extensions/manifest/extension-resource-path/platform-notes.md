
- **SwiftUI**: the source (`ExtensionResourcePath.swift`) is plain
  Foundation — `URL` and, transitively through `NSHomeDirectory()` and
  `FileManager.default.urls(for:in:)`, `FileManager` — with zero dependency
  on SwiftUI or any view-layer framework. It sits in `AgenticToolkitCore`,
  the tier reachable from both `Language/` (the snippet store) and
  `macOS/` (the theme, host, and plugin-manager call sites).
  `ExtensionResourcePathError` is declared `public enum` conforming to
  `Error`, `Equatable`, and `LocalizedError`; `ExtensionResourcePath` and
  `InstalledContentLocation` are both case-less enums used purely as
  static-function namespaces, with `resolve(_:inside:)` delegating to
  `resolve(_:relativeTo:containedIn:)`, and neither declares a `Sendable`
  conformance or any actor/`@MainActor` isolation — safe by construction
  rather than by explicit annotation, since every parameter and return
  value (`String`, `URL`, `Bool`) is itself `Sendable` and neither type
  holds mutable stored state. A port that keeps this component in Swift
  needs nothing beyond `Foundation`.
- **Compose**: there is no single JVM/Android API that reproduces this
  file's exact resolve-then-contain guarantee out of the box. Model
  `ExtensionResourcePathError` as a Kotlin `sealed class`/`data class` and
  `ExtensionResourcePath` as a Kotlin `object` namespace (the case-less-enum
  equivalent); build the candidate with `java.nio.file.Path.resolve` against
  a `Path.toRealPath()`-canonicalized base. `java.nio.file.Path.startsWith(Path)`
  is already component-aware, unlike a naive string check, so
  `component-wise-comparison` is largely free on this platform — the
  containment test becomes `candidate.startsWith(root) && candidate != root`.
  Compose the plugin/extension search directories from
  `System.getProperty("user.home")` plus a literal dot-prefixed name, and
  `Context.getExternalFilesDir`/`getFilesDir` in place of the Application
  Support directory.
- **React/Web**: for a Node-hosted extension runtime, use
  `path.resolve`/`path.normalize` for the candidate and `fs.realpathSync`
  (or its promise form) to resolve symlinks on both the base and the
  candidate before comparing. Node's `path` module has no built-in
  "is contained in" predicate, so the same component-wise comparison the
  source hand-rolls — never `String.prototype.startsWith`, which reproduces
  the exact sibling-directory bug `component-wise-comparison` guards
  against — has to be hand-rolled again here, typically via
  `path.relative(root, candidate)` checked for neither being absolute nor
  starting with a parent-directory segment. There is no direct Node
  equivalent of `~/Library/Application Support`; the nearest per-OS
  analogues are the platform's own config-directory environment variables,
  commonly wrapped by a small package that already normalizes across
  operating systems.
- **AppKit / UIKit**: identical to the SwiftUI note — the component depends
  on neither AppKit nor UIKit, so a macOS or iOS host consumes the same
  `AgenticToolkitCore` type directly with no translation needed.
- **WinUI 3**: there is no .NET or Windows App SDK type that performs this
  exact resolve-then-contain check. `Path.GetFullPath` alone does not
  resolve symlinks or junctions the way symlink resolution does in the
  source, so a port needs an explicit link-resolution step chained with
  `Path.GetFullPath` before the containment comparison. Compare with
  `Path.GetRelativePath(root, candidate)` and reject a result that is
  rooted or begins with a parent-directory segment, rather than
  `string.StartsWith`, for the same component-versus-string-prefix reason
  `component-wise-comparison` exists for in the source. `InstalledContentLocation`'s
  two locations map to `Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData)`
  (the Application Support analogue) and, for the hand-filled dotfolder, a
  subfolder of `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)`
  — Windows has no hidden-by-leading-dot convention, so hiding that folder
  needs an explicit hidden-attribute flag rather than relying on a leading
  dot the way macOS does. `HttpClient`, `System.Text.Json`, `Task`/`async`,
  `ObservableCollection`, and `INotifyPropertyChanged` all have no role
  here: every operation in the source is synchronous, non-networked,
  non-serializing, and returns a value rather than raising a change
  notification.

