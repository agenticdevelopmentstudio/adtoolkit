
**Decision**: (Apple platforms) A snapshot's stable `id` is a `UUID` separate from the CGWindowID, and the CGWindowID is optional.
**Rationale**: Per the `SystemWindowSnapshot` doc comment, the CGWindowID "may become stale after restart"; a separate stable ID lets a context keep a dormant snapshot and re-attach a new live window to it through the fingerprint.
**Approved**: pending

**Decision**: `SystemWindowFingerprint.titlePattern` holds regex source, not a captured value, for `appAndTitleRegex`.
**Rationale**: Per the `MatchStrategy.appAndTitleRegex` doc comment, storing the source means "every title in the same family re-matches after restart" (for example every `JIRA-<n>` window).
**Approved**: pending

**Decision**: The snapshot stores `display` and `app` beside the fingerprint's own copies.
**Rationale**: `display` is the restore target and changes when the user moves the window, while `fingerprint.display` records where it was first seen for tie-breaking; `app` is duplicated for direct access and nothing enforces equality.
**Approved**: pending

**Decision**: `SystemWindowContext` does not enforce unique `windowID`s or a valid `lastFocusedWindowID`.
**Rationale**: The value type stays a plain container; cross-context rules (a window in at most one context) need the whole context list, so `SystemWindowContextManager` enforces them.
**Approved**: pending

**Decision**: (Apple platforms) `MatchStrategy.displayName` lives on the model and returns English literals.
**Rationale**: The doc comment keeps it beside the enum, like `CustomMatchMode.displayName`, so hosts read labels without reaching into the macOS UI layer; the strings are not externalized, which is recorded as a failed check under Compliance.
**Approved**: pending

**Decision**: (Apple platforms) The types rely on synthesized `Codable` with no versioning.
**Rationale**: Synthesis keeps the wire format equal to the Swift property names; the cost is that a missing key or unknown strategy fails the whole decode, which the store reports as a decode error.
**Approved**: pending

