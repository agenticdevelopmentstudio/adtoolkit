
- **SwiftUI**: Both types (`IDEDetector.swift`, `LanguageDetection.swift`,
  test `Tests/AgenticToolkitMacOSTests/FileBrowser/LanguageDetectionTests.swift`)
  are consumed by SwiftUI-adjacent AppKit code today (`FileTreeManager`,
  `FileEditorState`) but have no SwiftUI import of their own. A SwiftUI
  consumer would drive `IDEDetector` as an `@ObservedObject`/
  `@StateObject`, calling `detect()` in `.task`/`.onAppear` and rendering
  `detectedIDEs` with `systemImageName` as an `Image(systemName:)`.
- **Compose**: Model `IDEType` as a Kotlin `enum class IDEType(val
  rawValue: String)` with `displayName`/`bundleIdentifier` as computed
  properties mirroring the `switch` statements, and `IDEProject` as a
  `data class` (Kotlin's structural `equals`/`hashCode` give
  `Equatable`/`Hashable` for free). Run the scan on
  `Dispatchers.IO` inside a `ViewModel`'s `viewModelScope`, exposing
  `detectedIDEs` as a `StateFlow<List<IDEProject>>` in place of `@Published`.
  `LanguageDetection` becomes a Kotlin `object` with the same two pure
  functions, backed by whatever tree-sitter/language-table equivalent
  Compose's editor stack uses in place of `CodeEditLanguages`.
- **React/Web**: There is no local file system to scan in a browser
  context, so `IDEDetector`'s marker-scanning has no direct web
  equivalent; a server-side or Electron-hosted port would run the same
  directory-walk logic in Node's `fs` module. `LanguageDetection.language`
  ports directly as a pure function over a filename string, keyed off a
  `Record<string, LanguageId>` extension table (the web equivalent of
  `CodeLanguage.allLanguages`), with the custom-override check as a
  user-settings lookup consulted first.
- **AppKit / UIKit**: `IDEDetector` is declared `@MainActor` and conforms
  to `ObservableObject`, publishing `detectedIDEs` and `isDetecting` as
  `@Published` properties; `detect()` dispatches the scan onto
  `DispatchQueue.global(qos: .userInitiated)` and publishes the result back
  on `DispatchQueue.main`, guarding against a deallocated instance with a
  weak-self check. `systemImageName` returns the SF Symbol name for each
  of the six cases — `"hammer.fill"` (Xcode), `"hammer"` (Xcode Workspace),
  `"shippingbox"` (Swift Package), `"chevron.left.forwardslash.chevron.right"`
  (VS Code), `"lightbulb.fill"` (IntelliJ IDEA), `"apps.iphone"` (Android
  Studio) — for use as `Image(systemName:)`/
  `NSImage(systemSymbolName:accessibilityDescription:)`. `IDEDetector.open`
  is AppKit-specific today: it resolves the associated application via
  `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` and opens
  it with `NSWorkspace.shared.open(_:withApplicationAt:configuration:)`,
  falling back to the parameterless `NSWorkspace.shared.open(targetURL)`
  when no bundle identifier resolves or that call fails; a failure from the
  bundle-application path is logged with `error.localizedDescription`. A
  UIKit port has no equivalent concept of "open an external IDE
  application" and would drop that function entirely, while the
  marker-scanning half of `IDEDetector` (`scan`, `matchMarkers`,
  `isMarkerDirectory`, `detectJetBrainsType`, `relativePathString`) is
  plain Foundation and UI-framework-agnostic. Logging uses `os.Logger` via
  the shared `Loggable` protocol, with `Bundle.main.bundleIdentifier` as
  the subsystem and `IDEDetector` as the category — `LanguageDetection`
  conforms to neither `Loggable` nor any AppKit or UIKit protocol, and has
  no AppKit or UIKit dependency at all.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `IDEType` as a C# `enum IDEType { Xcode, XcodeWorkspace, SwiftPackage,
  VSCode, IntelliJ, AndroidStudio }` with `DisplayName`/`SystemImageName`/
  `BundleIdentifier`-equivalent `string`-returning `switch` expressions
  mirroring the Swift computed properties exactly (Windows has no SF
  Symbol or bundle-identifier equivalent, so `SystemImageName` becomes a
  `Segoe Fluent Icons` glyph key and `BundleIdentifier` becomes an
  `AppUserModelId`/registered-file-association lookup via
  `Windows.System.Launcher.FindUriSchemeHandlersAsync` or
  `Windows.Storage.StorageFile` association APIs, used the same way
  `NSWorkspace.urlForApplication(withBundleIdentifier:)` is used here).
  Model `IDEProject` as a C# `record` for value semantics. Implement
  `scan`/`matchMarkers`/`isMarkerDirectory`/`detectJetBrainsType` with
  `System.IO.Directory.EnumerateFileSystemEntries` wrapped in `try`/`catch`
  in place of Swift's `try?`, preserving the same per-call-site failure
  granularity (whole-scan abort vs. single-directory skip vs. default
  fallback) documented in the `scan-*-failure-*` requirements. Run
  `Scan` on `Task.Run` (in place of `DispatchQueue.global`) and marshal
  the result back with the UI-thread dispatcher (in place of
  `DispatchQueue.main`), guarding re-entrancy with the same `IsDetecting`
  boolean check. Implement `Open` with
  `Windows.System.Launcher.LaunchUriAsync`/`LaunchFileAsync`, trying a
  resolved handler first and falling back to the OS default the same way
  the two-branch Swift `open` does, and log failures with whatever
  logging abstraction the WinUI host uses in place of `os.Logger`.
  For `LanguageDetection`, port `language(for:)` and
  `lspLanguageId(for:)` as static methods on a C# `static class`, with
  `CodeLanguage.allLanguages`'s Windows-side editor-language table
  substituted for `CodeEditLanguages`, and the same
  fixed-remap-then-passthrough `switch` for `LspLanguageId`.

