
- **Swift (source)**: This component targets macOS today, via the
  `AgenticToolkitCore` framework target (`project.yml`); nothing in it — a
  caseless `enum` of `static func`s over Foundation's `FileManager`,
  `Data`, `JSONSerialization`, and the sibling `JSONCPreprocessor` helper —
  depends on `AppKit`, `UIKit`, or any other platform framework, so the
  same source would run identically if the target grew an iOS platform
  tomorrow. The localization function does not declare `throws`; every
  internal step that can fail (`JSONCPreprocessor.jsonObject(from:)` for
  the manifest or a table, `JSONSerialization.data(withJSONObject:)` for
  the rewritten tree, `FileManager.default.contentsOfDirectory(atPath:)`
  for the directory listing, `Data(contentsOf:)` for one table's bytes) is
  wrapped in `try?` at its call site, converting a thrown error into the
  appropriate empty/unchanged result inline rather than propagating it.
  `JSONSerialization.data(withJSONObject:)` requires a top-level `Array` or
  `Dictionary` and throws for a bare `String`, which is why a manifest
  whose top-level JSON value is a bare string cannot round-trip through the
  substitution path. Both of the manifest's readers (`ExtensionRegistry.read`,
  `VSIXInstaller.readManifest`) call the localization function from
  `nonisolated` contexts, consistent with this component holding no actor
  or `@MainActor` isolation of its own.
- **Compose/Android (Kotlin)**: `java.io.File.listFiles()` replaces
  `FileManager.default.contentsOfDirectory(atPath:)`; `java.util.Locale` (or
  Android's `LocaleListCompat`) replaces `Locale`; `kotlinx.serialization`'s
  `JsonElement` tree (`JsonPrimitive`/`JsonArray`/`JsonObject`) replaces the
  `Any`-typed tree this file walks, and a recursive `when` over those three
  cases is the equivalent of `substituting(_:using:)`.
- **React/Web/TypeScript**: Node's `fs.readdirSync`/`fs.readFileSync`
  replace the `FileManager` calls; `Intl.Locale` (or a plain BCP-47 string)
  replaces `Locale`; `JSON.parse` plus a recursive walk that branches on
  `typeof value` (`"string"` versus `Array.isArray(value)` versus a plain
  object) replaces `substituting`, and `value.startsWith("%") &&
  value.endsWith("%") && value.length > 2` is the direct equivalent of the
  whole-string placeholder test.
- **WinUI 3 (C#)**: `System.IO.Directory.GetFiles`/`File.ReadAllBytes`
  replace the `FileManager` calls; `System.Globalization.CultureInfo`
  replaces `Locale`, with `CultureInfo.TwoLetterISOLanguageName` and
  `CultureInfo.Name`'s region subtag standing in for
  `locale.language.languageCode`/`locale.region`; `System.Text.Json.Nodes.JsonNode`
  (`JsonObject`/`JsonArray`/`JsonValue`) replaces the `Any`-typed tree, and a
  recursive method matching on `JsonNode.GetValueKind()` is the equivalent of
  `substituting(_:using:)`, writing back through `JsonNode.ToJsonString()` in
  place of `JSONSerialization.data(withJSONObject:)`. One genuine platform
  difference: NTFS resolves filenames case-insensitively by default, so the
  explicit lower-casing this file does in `fileNames(in:)` to
  match `package.nls.pt-BR.json` against a request for `package.nls.pt-br.json`
  is redundant on Windows — `File.Exists`/`Directory.GetFiles` already treat
  the two names as the same file, and a WinUI 3 port can rely on that instead
  of building its own case-folded lookup table.

