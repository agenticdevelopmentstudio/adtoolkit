
- **SwiftUI**: Source: `packages/apple/AgenticToolkit/Core/JSON/
  JSONCPreprocessor.swift`, part of the `AgenticToolkitCore` framework
  target, which `project.yml` declares `platform: macOS` only (no iOS
  target exists for it today). The file imports only `Foundation`; nothing
  in it is SwiftUI- or AppKit-specific, so a macOS or iOS host consumes it
  identically wherever it is built.
- **Compose**: There is no JSONC-aware parser in the Kotlin standard
  library or `kotlinx.serialization`. Port the comment- and
  trailing-comma-removal passes as hand-written scanner functions over a
  `CharSequence`, preserving the same in-string/escape tracking, then
  decode the result with `kotlinx.serialization.json.Json`. Port the
  six-candidate encoding loop with `Charsets.UTF_8`, `Charsets.UTF_16BE`,
  `Charsets.UTF_16LE`, and the UTF-32 equivalents obtained via
  `Charset.forName`, decoding with a `CharsetDecoder` configured
  `onMalformedInput(CodingErrorAction.REPORT)` so a bad candidate throws
  rather than silently substituting replacement characters — the behavior
  Swift's `String(data:encoding:)` gives for free by returning `nil`.
- **React/Web**: `jsonc-parser` — the library VS Code's own extension host
  uses — already implements this exact dialect; port by depending on its
  `parse`/`parseTree` functions rather than hand-rolling the scanner. There
  is no six-encoding ambiguity to resolve in a browser or Node environment:
  a `File`/`Blob`/`Buffer` decodes via an explicit or sniffed `TextDecoder`
  encoding, not tried six ways in sequence. The
  **jsonobject-rejects-top-level-fragments** /
  **jsondata-passthrough-when-already-strict** asymmetry has no natural
  analogue, since `JSON.parse` always accepts a top-level scalar; a port
  that wants to preserve the asymmetry must gate its two entry points
  deliberately rather than getting it from the underlying parser.
- **AppKit / UIKit**: This recipe is `JSONCPreprocessor`
  (`JSONCPreprocessor.swift`), declared as a caseless `enum` — a
  Foundation-only namespace holding no instance and no mutable state, with
  its only stored property (`candidateEncodings`) an immutable `static
  let`, and no actor isolation of any kind, which together give it
  **stateless-concurrency-safety** for free. Its three functions are
  `strip(_:)`, `jsonObject(from:)`, and `jsonData(from:)`; the comment and
  trailing-comma scanners (`removingComments`, `removingTrailingCommas`)
  operate on Swift `Character` (extended grapheme cluster) values, not raw
  code units, which is what keeps multi-byte and combined Unicode
  characters inside string literals from being misread as ASCII
  punctuation. `no-side-effects` holds because the source imports only
  `Foundation` and contains no `FileManager`, `URLSession`, `Process`, or
  `NotificationCenter` reference. `jsonObject(from:)` decodes candidates via
  `String(data:encoding:)` against `.utf8`, `.utf16`, `.utf16BigEndian`,
  `.utf16LittleEndian`, `.utf32BigEndian`, `.utf32LittleEndian` in that
  order, and both it and `jsonData(from:)`'s re-encode path call
  `JSONSerialization.jsonObject(with:)` — never passing `.fragmentsAllowed`
  — which is what makes **jsonobject-rejects-top-level-fragments** true;
  `jsonData(from:)`'s own initial strict-JSON check calls
  `JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])`
  directly against the original bytes, and its re-encode path serializes
  via `JSONSerialization.data(withJSONObject:options: [.fragmentsAllowed])`.
  Per its own doc comment, this type was lifted out of `VSCodeThemeImporter`
  's private copy when a second caller, `SnippetFile` in the
  `AgenticToolkitLanguage` framework target, needed the same JSONC-reading
  behavior; `ExtensionManifestLocalization`, `ExtensionRegistry`, and
  `VSIXInstaller` are its other callers in this repository, reading
  extension `package.json` manifests, `package.nls*.json` localization
  tables, and VS Code color themes and snippet files.
- **WinUI 3**: `System.Text.Json`'s `JsonDocumentOptions`/
  `JsonSerializerOptions` already expose `CommentHandling =
  JsonCommentHandling.Skip` and `AllowTrailingCommas = true` — a WinUI 3
  port SHOULD set those options on `JsonDocument.Parse`/
  `JsonSerializer.Deserialize` instead of reimplementing the comment and
  trailing-comma scanners by hand, since the built-in options already
  provide the same string-aware comment and trailing-comma tolerance. Only
  the six-candidate encoding fallback needs its own port: try
  `Encoding.UTF8`, `Encoding.Unicode` (UTF-16LE), `Encoding.BigEndianUnicode`
  (UTF-16BE), and `Encoding.UTF32` plus its big-endian counterpart via
  `Encoding.GetEncoding(...)`, decoding with `Encoding.GetString` configured
  with a `DecoderExceptionFallback` (so a candidate that cannot decode
  throws a `DecoderFallbackException` instead of silently substituting
  replacement characters) to reproduce Swift's nil-on-failure decode
  signal. `Windows.Storage`/`StorageFile` never enters this component at
  all — the byte source stays the caller's concern.

