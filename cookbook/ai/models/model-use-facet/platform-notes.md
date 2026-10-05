
- **SwiftUI**: The source (`packages/apple/AgenticToolkit/AIPluginKit/ModelUseFacet.swift`,
  companion `ModelCapability.swift`, tests
  `Tests/AIPluginKitTests/ModelUseFacetTests.swift`) has no SwiftUI or AppKit
  dependency of its own — it is plain Swift, framework-agnostic. It is
  consumed today by AppKit view controllers under
  `macOS/Features/AIPlugins/Settings/` (`ModelChooserViewController`,
  `ModelChooserContent`, `ProviderPickerViewController`) purely as a pure
  function call; a SwiftUI consumer would call the same `facets`/`matches`
  API with no changes to this type, likely driving a `Picker` or a row of
  `Toggle`s from `ModelUseFacet.allCases` bound to a `@State
  Set<ModelUseFacet>`.
- **Compose**: Model as a Kotlin `enum class ModelUseFacet(val title: String,
  val detail: String)` with the ten cases as enumerants carrying their label
  and tooltip directly, matching the Swift `switch`-per-property shape.
  Reproduce `wordPrefixes`/`phrases` as `private val` lists on each
  enumerant, `impliedByCapability` as a nullable `ModelCapability?` property,
  and `facets(text:capabilities:)`/`matches(...)` as top-level (or
  companion-object) pure functions returning `Set<ModelUseFacet>` /
  `Boolean` — no Compose-specific API is needed since the type itself has no
  UI dependency, only its consumers (a `FilterChip` row) would use Compose.
- **React/Web**: Model the ten cases as a `const enum ModelUseFacet = {
  Coding: "coding", Conversation: "conversation", ... } as const` (or a
  string-literal union type) with parallel `TITLES`/`DETAILS` lookup records
  keyed by the same values. Port `facets(text, capabilities)` as a pure
  function using `text.toLowerCase()`, a tokenizer regex
  (`text.match(/[\p{L}\p{N}]+/gu)`) for `word-tokenization`, `.startsWith()`
  per prefix for `word-prefix-anchoring`, and `.includes()` per phrase for
  `phrase-matching-on-raw-text`; return a `Set<ModelUseFacet>` (native `Set`)
  and implement `matches(facets, selected)` with `Set` operations
  (`selected.size === 0 || facets.size === 0 ||
  [...facets].some(f => selected.has(f))`).
- **AppKit / UIKit**: No AppKit- or UIKit-specific API appears in this file;
  it is genuinely UI-framework-agnostic and only consumed by the AppKit view
  controllers named above. A UIKit consumer (e.g. an iOS provider-settings
  screen) would call the same `facets`/`matches` API unchanged, driving a
  `UIMenu` or a table of checkable rows instead of AppKit's
  `MultiChoiceFilterButton`.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `ModelUseFacet` as a C# `enum ModelUseFacet { Coding, Conversation,
  ProblemSolving, Research, Writing, Vision, Agents, Translation, Speech,
  Economy }` plus a `static class ModelUseFacetInfo` exposing `Title`/`Detail`
  lookups (a `Dictionary<ModelUseFacet, string>` or a `switch` expression),
  matching `title`/`detail`. Reproduce `wordPrefixes`/`phrases` as
  `IReadOnlyList<string>` returned from a `switch` on the enum, and
  `impliedByCapability` as a `ModelCapability?` (nullable enum) switch
  mirroring `ModelUseFacet.swift`. Port `facets(text, capabilities)`
  using `text.ToLowerInvariant()`, `System.Globalization`-aware tokenizing
  (split on runs where `!char.IsLetterOrDigit(c)`) for `word-tokenization`,
  `word.StartsWith(prefix, StringComparison.Ordinal)` for
  `word-prefix-anchoring`, and `lowered.Contains(phrase)` for
  `phrase-matching-on-raw-text`; return a `HashSet<ModelUseFacet>` (the
  `Set<T>` equivalent) and implement `Matches(facets, selected)` with
  `HashSet<T>.Overlaps` (`selected.Count == 0 || facets.Count == 0 ||
  facets.Overlaps(selected)`) to mirror `!facets.isDisjoint(with:)`. No
  `HttpClient`, `System.Text.Json`, `Windows.Storage`, or `Task`/`async` is
  needed — every operation here is synchronous, in-memory string matching,
  just as in the Swift source.

