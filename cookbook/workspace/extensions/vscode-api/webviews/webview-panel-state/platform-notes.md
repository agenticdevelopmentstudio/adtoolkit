
- **SwiftUI**: the source (`WebviewPanelState.swift`) is plain
  `Foundation` — `JSONEncoder`, `JSONDecoder`, `Data`, `String` — with no
  dependency on SwiftUI or any view-layer framework. It sits in
  `AgenticToolkitCore`, alongside its sibling `WebviewPanelOptions`, and is
  consumed by the `macOS`-tier `WebviewPanelViewController` and
  `WebviewPanelSerializer`. A port that keeps this type in Swift needs
  nothing beyond `Foundation` and `Codable`. `WebviewPanelState` is a
  `public struct` conforming to `Codable`, `Equatable`, and `Sendable`, with
  exactly the four stored properties named above (`viewType: String`,
  `title: String`, `state: String?`, `options: WebviewPanelOptions`);
  "constructing this component from its four fields" above is
  `init(viewType:title:state:options:)`. "Encoding this component" above is
  `encoded()`, which configures its `JSONEncoder` with
  `outputFormatting = .sortedKeys` to reproduce **sorted-key-encoding**, and
  fails with `WebviewPanelStateError.encodedTextIsNotUTF8` rather than
  force-unwrapping the UTF-8 conversion. "Decoding this component from a
  stored string" is `init(json:)`, which decodes `Self` from the string's
  UTF-8 bytes via `JSONDecoder`. `encode(to:)` uses `encodeIfPresent` for
  `state` (reproducing **absent-state-omits-key**); `init(from:)` decodes
  `viewType` with `decode(String.self, forKey: .viewType)` (not
  `decodeIfPresent`, reproducing **missing-view-type-refused**), `title`
  with `decodeIfPresent(String.self, forKey: .title) ?? ""`, and `options`
  with `decodeIfPresent(WebviewPanelOptions.self, forKey: .options) ??
  WebviewPanelOptions(enableScripts: nil, enableForms: nil,
  localResourceRoots: nil)`. Both methods key their container on the same
  `CodingKeys` case set (`viewType`, `title`, `state`, `options`), giving
  **fixed-coding-keys** and, by `Codable`'s own contract, **unknown-fields-ignored**
  for free. **safe-for-concurrent-access** above follows from
  `WebviewPanelState`'s explicit `Sendable` conformance: every stored
  property (`String`, `String?`, `WebviewPanelOptions`, itself `Sendable`)
  is immutable (`let`) and itself `Sendable`.
- **Compose**: model `WebviewPanelState` as a Kotlin `data class` with the
  same four properties, and use `kotlinx.serialization`'s `@Serializable`
  with an explicit sorted-key JSON configuration (or sort the resulting
  `JsonObject`'s keys before serializing to text, since `kotlinx.serialization`
  does not sort keys by default) to reproduce `sorted-key-encoding`.
  `viewType` as a non-optional, non-defaulted constructor parameter
  reproduces `missing-view-type-refused` automatically, since
  `kotlinx.serialization` throws on a missing required field; `title`,
  `state`, and `options` need explicit default values or
  `@EncodeDefault`/nullable handling to reproduce the other three fields'
  defaulting behavior.
- **React/Web**: represent the shape as a plain TypeScript interface with
  `viewType: string`, `title: string`, `state: string | null`, and
  `options: WebviewPanelOptions`. `JSON.stringify` does not sort object keys,
  so reproducing `sorted-key-encoding` needs an explicit
  `Object.keys(value).sort()` replacer function passed to `JSON.stringify`.
  `JSON.parse` on the stored text, followed by manual field-by-field
  validation (throwing when `viewType` is missing or not a string,
  defaulting `title` to `""` and `options` to the safe posture when absent)
  reproduces the decode-side behavior, since there is no built-in decoder
  that enforces per-field presence the way Swift's `Codable` does.
- **AppKit / UIKit**: identical to the SwiftUI note — the type depends on
  neither AppKit nor UIKit, so a macOS host consumes the same
  `AgenticToolkitCore` type directly with no translation needed. (The panel
  that actually renders from a restored value, `WebviewPanelViewController`,
  is AppKit and is out of this file's own scope.)
- **WinUI 3**: use `System.Text.Json` with a `JsonSerializerOptions` whose
  `PropertyNamingPolicy` is left alone (the field names already match) and
  whose writer is configured, or whose properties are alphabetized before
  serialization, to reproduce `sorted-key-encoding` — `System.Text.Json` does
  not sort properties by declaration order by default, so an explicit
  ordering step is needed. Model `state` as a nullable `string?` mapped with
  `JsonIgnoreCondition.WhenWritingNull` on the property so a `null` state
  omits the key exactly as `encodeIfPresent` does, reproducing
  `absent-state-omits-key`. Make `viewType` a required constructor parameter
  (a C# 11 `required` property, or a positional record parameter with no
  default) so `System.Text.Json` throws `JsonException` on missing JSON
  rather than defaulting it, reproducing `missing-view-type-refused`; give
  `title` and `options` explicit fallback values in the deserializing
  constructor to reproduce their defaulting behavior. `HttpClient`,
  `Windows.Storage`, `Task`/`async`, `ObservableCollection`, and
  `INotifyPropertyChanged` all have no role here: every operation in the
  source is synchronous, non-networked, and returns a value rather than
  raising a change notification.

