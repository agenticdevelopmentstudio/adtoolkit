
- **Swift (source)**: This component targets macOS today, via the
  `AgenticToolkitCore` framework target (`project.yml`); nothing in it —
  plain `Codable`/`Sendable` structs and enums over Foundation's
  `JSONDecoder`/`JSONEncoder` — depends on `AppKit`, `UIKit`, or any other
  platform framework, so the same source would decode identically if the
  target grew an iOS platform tomorrow. Every field and value type in this
  file is `Codable`; the top-level identity fields (`name`, `version`,
  `engines.vscode`, `contributes`) are decoded with `container.decode`/`decodeIfPresent`
  with no `try?`, while every other optional or per-element field is
  decoded via `try?` (or the equivalent per-element `LenientDecoding.array`/`.dictionary`/`.value`
  helpers), which is the Swift mechanism behind every "independently
  tolerant" requirement above. `JSONValue` is declared nested as
  `ExtensionManifest.JSONValue` rather than as a bare top-level type,
  because a bare top-level `public enum JSONValue` in this module is
  flagged `duplicate_name` by `abstractr check --content-file` against the
  sibling foundation tier `AgenticToolkitSync`'s own top-level `JSONValue`.
  `describe(_:)` switches on the four `DecodingError` cases (`.keyNotFound`,
  `.typeMismatch`, `.valueNotFound`, `.dataCorrupted`) plus a catch-all for
  `DecodingError.@unknown default` and any non-`DecodingError` `Error`,
  rendering `error.localizedDescription` for the latter.
  `decodingFailures`/`Contributions.decodingFailures` are excluded from
  `CodingKeys` so `Encodable` synthesis never emits them. `ExtensionManifest`,
  `Contributions`, and every nested type are declared `Sendable` and
  `Equatable` with no `actor` or `@MainActor` isolation, matching
  `manifest-and-contributions-are-thread-safe`. The ~275ms-per-100-extension
  recovery-path cost cited in `lenient-array-strict-first-perf-rationale`
  was measured as main-actor CPU time in `ExtensionRegistryTests`' `F52`
  benchmark.
- **React/Web/TypeScript**: A hand-rolled parser, or a schema library such
  as `zod`/`io-ts`, replaces `Codable`; the same per-element try/catch-and-continue
  loop `LenientDecoding.array`/`.dictionary` implement is idiomatic
  TypeScript (a `for` loop wrapping each element's `schema.parse` in its own
  `try { } catch { }`), and a discriminated union is the equivalent of
  `PropertyType`.
- **Compose/Android (Kotlin)**: `kotlinx.serialization` with a custom
  `KSerializer`, or Moshi/Gson with a custom `JsonAdapter`, replaces
  `Codable`; a `sealed interface` with `data class`/`object` cases is the
  equivalent of `JSONValue`, and the same strict-first/per-element-fallback
  pattern is implemented by catching `SerializationException` around each
  array element's own `Json.decodeFromJsonElement` call.
- **WinUI 3 (C#)**: `System.Text.Json` (`JsonSerializer`, `JsonDocument`,
  `JsonElement`) replaces `Codable`; `System.Text.Json.Nodes.JsonNode` is the
  equivalent of `JSONValue`. A custom `JsonConverter<T>` per contribution
  type, reading via `Utf8JsonReader`/`JsonElement` and wrapping each
  element's conversion in its own `try`/`catch (JsonException)`, is the
  equivalent of `LenientDecoding.array`/`.dictionary`'s per-element
  isolation; a `record` with nullable properties plays the role of this
  file's `try?`-decoded optional fields, and an immutable `record` — never
  an `ObservableCollection<T>`, which nothing in this file's contract needs
  — is the equivalent of the `Sendable`, value-type `Contributions`.

