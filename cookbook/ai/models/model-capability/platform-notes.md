
- **SwiftUI**: The source (`packages/apple/AgenticToolkit/AIPluginKit/ModelCapability.swift`,
  tests `Tests/AIPluginKitTests/ModelCapabilityTests.swift`) has no
  SwiftUI dependency of its own — it is plain Swift, framework-agnostic.
  A SwiftUI consumer would render `ForEach(ModelCapability.allCases)` as a
  table column, using `title` as the header and `has(_:_:)`/
  `capabilities(of:)` to decide the check mark, with no change to this
  type.
- **Compose**: Model as a Kotlin `enum class ModelCapability(val
  rawValue: String) { TOOLS("tools"), REASONING("reasoning"),
  VISION("vision"), CONVERSATION("conversation") }` with `title`/`detail`
  computed properties mirroring the Swift `switch` statements, and a
  private `reportedNames: List<String>` per case. Implement `reports`,
  `has`, and `capabilitiesOf` as functions on a companion `object`, using
  `.lowercase()` for the case-insensitive comparison and `entries` (the
  Kotlin `enum class` equivalent of `CaseIterable.allCases`, in
  declaration order) for `capabilitiesOf`.
- **React/Web**: `type ModelCapability = "tools" | "reasoning" | "vision"
  | "conversation"` as a string union, plus `const ALL_CAPABILITIES:
  ModelCapability[] = ["tools", "reasoning", "vision", "conversation"]`
  mirroring `allCases`' declaration order. `title`/`detail` as `Record<
  ModelCapability, string>` lookup maps, `reportedNames` as `Record<
  ModelCapability, string[]>`, and `reports`/`has`/`capabilitiesOf` as
  pure functions over a `ResolvedModel` interface, using
  `.toLowerCase()` plus `Array.prototype.includes` for the
  case-insensitive match.
- **AppKit / UIKit**: No AppKit- or UIKit-specific API appears in this
  file; it is UI-framework-agnostic. It is consumed today by AppKit
  table/column code that renders one column per `ModelCapability` with a
  check mark keyed by `has(_:_:)` — nothing in this type changes to run
  under UIKit, only the consuming view.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `ModelCapability` as a C# `enum ModelCapability { Tools, Reasoning,
  Vision, Conversation }` with a
  `[JsonConverter(typeof(JsonStringEnumConverter))]` using a naming
  policy that lowercases case names, so it round-trips through
  `System.Text.Json` as the same `tools`/`reasoning`/`vision`/
  `conversation` wire strings `Codable` produces. Give `Title`/`Detail`
  as `string`-returning `switch` expressions mirroring the Swift
  `title`/`detail` computed properties exactly. Store the per-case
  spelling vocabulary as a `static readonly Dictionary<ModelCapability,
  string[]> ReportedNames`, and implement `Reports(ModelCapability,
  IEnumerable<string>)` as `capabilities.Any(c =>
  names.Contains(c.ToLowerInvariant()))` (mirroring the Swift `Set` +
  case-insensitive `contains`). Implement `Has(ModelCapability,
  ResolvedModel, string? extraText = null)` with the same
  report-first-then-per-case-fallback short circuit (`ResolvedModel.Tools
  == true` for Tools; a `ModelUseFacet` port's `Facets(...)` for
  Conversation; a hard `false` for Reasoning/Vision). Implement
  `CapabilitiesOf(ResolvedModel, string? extraText = null)` as
  `Enum.GetValues<ModelCapability>().Where(c => Has(c, info,
  extraText))`, which preserves declaration order the same way
  `CaseIterable.allCases` does in Swift. Bind `Title` to an
  `ItemsRepeater`/`GridView` column header `TextBlock` and `Detail` to
  that header's `ToolTipService.ToolTip` attached property, matching the
  Swift doc comment's own description of these two properties' UI role.

