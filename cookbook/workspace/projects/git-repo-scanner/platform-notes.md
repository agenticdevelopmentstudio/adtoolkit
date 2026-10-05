
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/GitRepoScanner.swift`,
  using Foundation's `FileManager`, `URL`, `URLResourceKey`, and the C
  `fnmatch`/`FNM_CASEFOLD` functions; its companion type `ScannedGitRepo`
  lives in `GitRepo.swift` in the same directory. Nothing here is
  SwiftUI-specific — the type has no view, no `@Observable`/`@Published`
  state, and touches no UI framework at all.
- **Compose**: Port `roots` and `rootSkipPatterns` as plain constructor
  parameters of a Kotlin class. Walk with `java.io.File.listFiles()` or
  `java.nio.file.Files.newDirectoryStream`, using an explicit
  `ArrayDeque<Pair<File, Int>>` as the LIFO stack in place of the Swift
  `stack` array. Java/Kotlin glob matching (`PathMatcher` via
  `FileSystems.getDefault().getPathMatcher("glob:...")`) is case-sensitive by
  default, so case-fold each name and pattern manually before comparing, in
  place of `FNM_CASEFOLD`. Parse `.git/config` with the same manual
  line-by-line scan rather than pulling in a full INI library, to preserve
  the "reads exactly the one section that matters" behavior.
- **React/Web**: A browser cannot walk a filesystem or read `.git/config` at
  all; a faithful port only exists in a Node-hosted process, using
  `fs.readdirSync`/`fs.promises.readdir` with `withFileTypes: true` (in
  place of the `URLResourceKey` lookups) and `fs.lstatSync().isSymbolicLink()`
  to exclude symlinks. Use `minimatch` with its `nocase: true` option in
  place of `fnmatch`+`FNM_CASEFOLD`. Read `.git/config` with
  `fs.readFileSync(configPath, 'utf8')` and reuse the same manual
  `[remote "origin"]` line scan.
- **AppKit / UIKit**: Identical to the SwiftUI note — `GitRepoScanner.swift`
  is UI-framework-independent. An iOS port faces a different constraint than
  a porting concern: the App Sandbox does not grant arbitrary access to a
  user's home directory the way this macOS-only file assumes, so an iOS port
  would need a user-picked folder (`UIDocumentPickerViewController`) or a
  security-scoped bookmark rather than defaulting to
  `FileManager.default.homeDirectoryForCurrentUser`.
- **WinUI 3**: Port the walk with
  `System.IO.Directory.EnumerateFileSystemEntries` (or
  `DirectoryInfo.EnumerateDirectories`/`EnumerateFiles`), wrapping each call
  in a `try`/`catch` over `UnauthorizedAccessException` and `IOException` the
  same way `contentsOfDirectory`'s `throws` is caught. Represent
  `rootSkipPatterns` as a `List<string>` matched case-insensitively with
  `System.IO.Enumeration.FileSystemName.MatchesSimpleExpression` (.NET has no
  direct `fnmatch` equivalent) rather than `Windows.Storage`, since nothing
  here is packaged-app storage. Read `.git\config` with
  `System.IO.File.ReadAllText` and reuse the same manual `[remote "origin"]`
  line scan rather than `System.Text.Json` or a full INI parser, since the
  format is not JSON. Represent `ScannedGitRepo` as a C# `record`, drive
  progress through an `IProgress<Progress>` callback in place of the
  `onProgress` closure, and check a `CancellationToken`'s
  `IsCancellationRequested` at the same per-directory granularity as
  `isCancelled()`.

