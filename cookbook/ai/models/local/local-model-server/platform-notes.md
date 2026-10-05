
- **SwiftUI**: The source
  (`packages/apple/AgenticToolkit/AIPluginKit/LocalModelServer.swift`,
  tested by `Tests/AIPluginKitTests/LocalModelServerTests.swift`) has no
  SwiftUI, or any UI framework, dependency — it is a plain
  `Foundation`-only Swift `enum` with no case. A SwiftUI model-picker view
  or its `@Observable`/`@State` view model can call any of its four static
  functions directly, synchronously, from any isolation domain (a `.task {
  }` modifier, a button action, or a background `Task`) with no adaptation.
  Concretely: loopback detection is `isLoopback(baseURL:)`, built on
  `URL(string:)?.host`; native tags URL derivation is
  `nativeTagsURL(baseURL:)`; the response parser is `parseSizes(_:)`,
  decoding with `JSONDecoder` and a private `Element` wrapper's `try?
  Model(from: decoder)` per array element to get per-entry tolerance; the
  size resolver is `size(of:in:)`. The type itself is `public` with no
  explicit `Sendable` conformance, which is immaterial given it has no
  stored instance state.
- **Compose**: There is no Compose-specific consideration since this is a
  data-shaping layer, not UI. A Kotlin port would be a top-level `object
  LocalModelServer` (a Kotlin singleton, the closest analogue to a caseless
  `enum` namespace) exposing the same four functions, using
  `java.net.URI`/`okhttp3.HttpUrl` for host parsing in place of `URL.host`,
  and `kotlinx.serialization`'s `Json` with a `JsonElement`-based per-entry
  decode loop (rather than a single `List<Model>` decode) to reproduce
  `parse-sizes-per-element-tolerance`, since a default `kotlinx.serialization`
  list decode fails the whole array on one malformed element.
- **React/Web**: A TypeScript module exporting the four functions (or a
  `LocalModelServer` namespace object) using the global `URL` for host
  parsing in `isLoopback`, plain string operations
  (`trimEnd`/`endsWith`/lowercasing) for `nativeTagsURL`'s trim-and-strip
  sequence, and a manual `for` loop over `parsed.models` with a per-element
  `try/catch` (rather than one `JSON.parse` of the whole body followed by a
  schema cast) to reproduce `parse-sizes-per-element-tolerance` — a single
  `JSON.parse` on the whole body still throws on invalid top-level JSON,
  matching `parse-sizes-whole-decode-failure-empty`'s empty-object result.
- **AppKit / UIKit**: This is exactly the source's own context. The
  `AIPluginKit` target that contains `LocalModelServer.swift` builds for
  macOS only (`platform: macOS` in `project.yml`), and is consumed from
  AppKit-hosted code at
  `AgenticToolkit/macOS/Features/AIPlugins/Settings/ModelChooserContent.swift`
  and `ModelChooserViewController.swift`, as well as from the non-UI
  callers `LocalModelCatalog.swift`, `LocalProviderModelStore.swift`, and
  `DaemonAIChat.swift`. Nothing in `LocalModelServer` itself is
  AppKit-specific; a UIKit host would call the same four functions
  identically, with no adaptation, if this target were ever built for iOS.
- **WinUI 3**: This is the platform this recipe exists to steer. Port
  `LocalModelServer` as a `static class LocalModelServer` in C#, with four
  static methods matching the source one-for-one: `bool IsLoopback(string
  baseUrl)` using `Uri.TryCreate(baseUrl, UriKind.Absolute, out var uri)`
  and `uri.Host.ToLowerInvariant()` checked against a `static readonly
  HashSet<string>` holding the same five literals
  (`"localhost"`, `"127.0.0.1"`, `"0.0.0.0"`, `"::1"`, `"[::1]"`), returning
  `false` when `TryCreate` fails or `uri.Host` is empty; `Uri?
  NativeTagsUrl(string baseUrl)` reproduces the trim → strip-trailing-`/` →
  strip-case-insensitive-`/v1`-suffix → strip-trailing-`/` → append
  `"/api/tags"` sequence with `string.Trim()` and `TrimEnd('/')`, an
  `EndsWith("/v1", StringComparison.OrdinalIgnoreCase)` check followed by
  `Substring(0, length - 3)`, and a final `Uri.TryCreate` (returning `null`
  on an empty result or a construction failure) in place of `URL(string:)`'s
  optional return; `Dictionary<string, long> ParseSizes(byte[] data)`
  deserializes with `System.Text.Json.JsonSerializer`, but because
  `System.Text.Json` fails the whole document on one malformed array
  element the same way a naive Kotlin or TypeScript port would, the
  per-element tolerance MUST be reimplemented explicitly — deserialize
  `models` as `JsonElement[]` and wrap each individual
  `element.Deserialize<Model>()` call in its own `try`/`catch` to match the
  `Element` wrapper's `try?`-per-entry semantics — populating the
  `Dictionary<string, long>` under both a `Name` and a `Model` key exactly
  as `sizes[name] = size` / `sizes[model] = size` do, including the
  later-entry-wins collision behavior of a plain dictionary-indexer
  assignment; `long? SizeOf(string model, IReadOnlyDictionary<string, long>
  sizes)` does `sizes.TryGetValue(model, out var v) ? v : sizes.TryGetValue(model
  + ":latest", out var v2) ? v2 : (long?)null`. None of `HttpClient`,
  `Windows.Storage`, `Task`/`async`, `ObservableCollection`, or
  `INotifyPropertyChanged` is needed by this type itself, since it performs
  no I/O and holds no observable state — those APIs belong to the caller
  (a `LocalModelCatalog`-equivalent) that fetches the `Uri` this type
  derives and hands this type the bytes it returns.

