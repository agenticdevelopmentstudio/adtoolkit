
- **SwiftUI**: the source (`ActivationEventMatcher.swift`,
  `ExtensionManifest.swift`, `VSCodeEngineRange.swift`,
  `SemanticVersion.swift`) is plain Foundation logic — value types, string
  parsing, and a hand-rolled backtracking matcher — with no dependency on
  SwiftUI or any view-layer framework. `ActivationEvent`, `ActivationTrigger`,
  `ActivationEvent.Kind`, `WorkspaceScan`, and `ActivationEventMatcher` are
  declared `Sendable` and `Equatable`; whitespace trimming uses Foundation's
  `.whitespaces` character set. Glob matching operates over Swift
  `Character` (extended grapheme cluster) elements of both pattern and path
  (see Design Decisions). A port that keeps this component in Swift needs
  nothing beyond `Foundation`.
- **Compose**: start from Kotlin `data class`/`sealed interface` for
  `ActivationEvent`/`ActivationTrigger` (a `sealed interface` models the
  `Kind`/`Trigger` enums with associated payloads more directly than a
  Kotlin `enum class`), plain `String` parsing for the prefix matching, and
  a hand-written recursive matcher for the glob logic — Kotlin's
  `Regex`/`glob` support does not implement VS Code's specific `**`
  whole-segment rule or its brace-alternation syntax, so translating glob
  to a JVM regex has the same escaping hazard the source's own doc comment
  gives for avoiding `NSRegularExpression`. Memoize with a plain
  `HashMap` keyed on the same `(tokenIndex, pathIndex)`/`(branchId,
  branchIndex, pathIndex)` shapes.
- **React/Web**: model `ActivationEvent`/`ActivationTrigger` as discriminated
  union types (a `kind` or `type` string field plus payload), parse
  `activationEvents` with the same ordered `if`/`else if` chain over
  `String.prototype.startsWith`, and port the glob matcher as a small
  recursive function over an array of tokens — `minimatch`/`micromatch`
  exist on npm but neither one, out of the box, restricts a bare `**` to
  crossing directories only when it is a whole path segment while treating
  every other `**` as a single `*`; that VS Code-specific rule (and the
  rejection of `[...]` classes and leading `!`) needs the same custom
  tokenizer the source implements, not a general-purpose glob library.
- **AppKit / UIKit**: identical to the SwiftUI note — the component depends
  on neither AppKit nor UIKit, so a macOS or iOS host consumes the same
  `AgenticToolkitCore` type directly with no translation.
- **WinUI 3**: there is no .NET or Windows App SDK type that already
  implements VS Code's `activationEvents` grammar or its `engines.vscode`
  range grammar, so both need a direct C# port rather than an existing
  library. Model `ActivationEvent`/`ActivationTrigger` as C# records with a
  discriminated `Kind`/`Trigger` (a base `abstract record` with derived
  records per case, or a single record carrying a `Kind` enum plus a
  nullable payload string) rather than reaching for `System.Text.Json`'s
  polymorphic serialization, since these values are constructed from
  parsed strings, not deserialized JSON. Port `VSCodeEngineRange` and
  `SemanticVersion` as plain C# `readonly struct`s with the same
  three-base/must-equal-flag representation — resist the temptation to
  reach for NuGet's `Semver` or `NuGet.Versioning` packages, since both
  implement npm/NuGet semver ranges, which is precisely the grammar the
  source's own doc comment says VS Code's `engines.vscode` is not. Port
  `GlobPattern` as a private nested class inside the equivalent of
  `ActivationEventMatcher` (mirroring the source's file-local placement)
  with its two memoization tables as `Dictionary<TKey, bool>` locals scoped
  to one `Matches` call, matching over a `char[]` (note: a C# `char` is a
  UTF-16 code unit, not a grapheme cluster the way a Swift `Character` is,
  so a path containing a combining-character sequence could tokenize
  differently between a Swift host and a WinUI 3 host — call this out in
  the port's own tests rather than assuming parity). `Task`/`async` and
  `ObservableCollection`/`INotifyPropertyChanged` have no role here: every
  operation is synchronous and returns a value rather than notifying of a
  change.

