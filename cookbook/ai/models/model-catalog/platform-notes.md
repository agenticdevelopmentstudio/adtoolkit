
- **SwiftUI**: The source (`packages/apple/AgenticToolkit/AIPluginKit/AIModelCatalog.swift`,
  bundled resource `model-catalog.json`, generator
  `packages/apple/AIPlugins/tools/generate_model_catalog.py`, tests
  `Tests/AIPluginKitTests/AIModelCatalogTests.swift`) has no SwiftUI
  dependency of its own — it is plain Swift, framework-agnostic. It is
  consumed today by AppKit view controllers under
  `macOS/Features/AIPlugins/Settings/` (`ModelPickerItem`,
  `ModelChooserViewController`, `ProviderPickerViewController`) purely as
  data; a SwiftUI consumer would call the same `resolve`/`model(named:)` API
  with no changes to this type. The framework's own resource-bundle lookup
  (`Bundle(for: BundleToken.self)`) needs a small anchor type — an empty
  class with no state, used solely so `Bundle(for:)` resolves to this
  framework's own bundle regardless of which app embeds it; it exists only
  because of this API's shape and has no analog outside it.
- **Compose**: Model as Kotlin `data class`es — `data class Model(val id:
  String, val aliases: List<String> = emptyList(), val description:
  String? = null, val capabilities: List<String> = emptyList())` and a
  matching `Offering`/`ResolvedModel`, giving structural equality for free
  (matching Swift's `Equatable`). `kotlinx.serialization` with `@Serializable`
  and default values on the constructor reproduces `decodeIfPresent(...) ??
  []`. Replace `byName`/`byCanonicalID` with two `Map<String, Model>` built in
  an `init {}` block, and load `model-catalog.json` as an Android asset via
  `context.assets.open(...)` wrapped in a `runCatching { }.getOrNull()` to
  mirror `load(from:)`'s total (never-throwing) contract.
- **React/Web**: `interface Model { id: string; aliases: string[]; description?:
  string; capabilities: string[] }` plus matching `Offering`/`ResolvedModel`
  interfaces. Parse with a runtime validator (e.g. zod) instead of Swift's
  throwing `Codable` initializer, applying the same empty-array/`undefined`
  defaults explicitly since `JSON.parse` performs no schema coercion. Build
  `byName`/`byCanonicalID` as two `Map<string, Model>` at module load, and
  memoize the parsed catalog in a module-level `let shared: AIModelCatalog |
  null` (lazily computed on first access) as the equivalent of Swift's
  `static let shared`.
- **AppKit / UIKit**: No AppKit- or UIKit-specific API appears in this file;
  it is genuinely UI-framework-agnostic and only consumed by the AppKit view
  controllers named above. Nothing in this type needs to change to run under
  UIKit — only the consuming views differ.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `Model`/`Offering`/`ResolvedModel` as C# `sealed record` types — e.g.
  `public sealed record Model(string Id, IReadOnlyList<string> Aliases,
  string? Description, IReadOnlyList<string> Capabilities)` — which give
  value semantics and structural equality matching Swift's `Equatable`.
  Decode with `System.Text.Json`'s `JsonSerializer.Deserialize<AIModelCatalog>`,
  using nullable properties with constructor defaults (or a custom
  `JsonConverter`) to reproduce `decodeIfPresent(...) ?? []`. Build
  `byName`/`byCanonicalID` as two `Dictionary<string, Model>` populated once
  in the record's constructor, exactly mirroring the Swift index-build loop
  (including last-writer-wins on a colliding key). Ship `model-catalog.json`
  as Content in the app package and load it via
  `Windows.ApplicationModel.Package.Current.InstalledLocation` (or an
  embedded-resource stream) instead of `Bundle.url(forResource:)`. Expose the
  loaded value through a `Lazy<AIModelCatalog>` (the `Lazy<T>` equivalent of
  Swift's `static let shared`), wrapping the file read and
  `JsonSerializer.Deserialize` call in a `try`/`catch` that falls back to an
  empty `AIModelCatalog` on any exception, matching `load(from:)`'s
  never-throw, empty-on-failure contract. `async`/`Task`-based file I/O is
  optional here since the resource is local and small; a synchronous read at
  startup is the direct port of the Swift `Bundle`/`Data(contentsOf:)` call.

