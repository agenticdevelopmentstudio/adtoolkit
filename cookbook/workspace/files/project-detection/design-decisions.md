
- **Decision**: The associated-application-identifier lookup keeps an
  optional return type even though every one of the current six cases
  returns a value.
  **Rationale**: the property's own documentation states it "Returns none
  for types that don't have a dedicated app," and the open operation
  already has a fallback branch for an absent identifier — the optional
  return type anticipates a future IDE-type case with no dedicated
  application, even though no such case exists in the source given here.
  **Approved**: pending
- **Decision**: The marker-matching step's `.xcworkspace` branch guards
  against the entry's parent directory having extension `"xcodeproj"`,
  even though the scan operation's own marker-directory exclusion already
  prevents recursing into any `.xcodeproj` directory, making that guard
  unreachable for any path the scan operation currently visits.
  **Rationale**: not explained in the source; documented here as an
  observed quirk (defensive code for a case the traversal design already
  rules out) rather than silently corrected or removed, per source
  fidelity.
  **Approved**: pending
- **Decision**: The LSP-language-id remap SHOULD remain the toolkit's one
  place that derives an LSP `languageId`, rather than every caller
  deriving it independently.
  **Rationale**: the language-server configuration component's own
  documentation explains that it sits in a lower dependency tier than the
  language-detection component's own module, and "dependencies point
  downward only," so it takes a caller-supplied plain string instead of
  importing this function — duplicating the remap table elsewhere risks
  reintroducing the `cSharp`/`csharp`-style mismatches this function
  exists to fix.
  **Approved**: pending
- **Decision**: The scan operation's two top-level listing calls fail
  differently — a failed visible-entries call aborts the whole scan
  (returns an empty result), while a failed hidden-entries call only drops
  hidden entries and continues.
  **Rationale**: not explained in source comments; documented here as an
  observed asymmetry rather than smoothed into a single uniform failure
  behavior, per source fidelity.
  **Approved**: pending

**Decision**: The IDE-marker detector cannot signal that its scan failed; an unreadable root and an empty root look the same.
**Rationale**: `IDEDetector.scan(rootURL:)` returns `[]` when the top-level `contentsOfDirectory` call fails, and `detect()` publishes that exactly like an empty result. Closing it would take a distinct failure state on the detector, which is a decision about what a caller should show for it.
**Approved**: pending

**Decision**: The fallback open's success indicator is never read, so a failed fallback open is silent.
**Rationale**: In `IDEDetector.open(project:rootURL:)` the `NSWorkspace.shared.open(targetURL)` fallback result is discarded, while the specific-application path logs its completion error. Closing it would take deciding what, if anything, the fallback path should report on failure.
**Approved**: pending

**Decision**: A custom mapping whose language name resolves to no known language is accepted and silently has no effect.
**Rationale**: `FileTypesSettingsView` only requires a non-empty language name, and `LanguageDetection.language(for:)` falls through to built-in detection when no `CodeLanguage` matches the name. Closing it would take validating or reporting an unresolvable name in the settings UI, the mapping lookup, or the resolver.
**Approved**: pending

**Decision**: The custom-mapping store's cache and active defaults key have no synchronization.
**Rationale**: `CustomFileTypeMappings` keeps `cache` and `activeDefaultsKey` as `nonisolated(unsafe)` statics, cleared by `save(_:)` and filled by `mapping(for:)`, while `LanguageDetection.language(for:)` may be called from any thread. Closing it would take a lock or actor isolation around the cache, which is a decision about what synchronization the store should adopt.
**Approved**: pending

