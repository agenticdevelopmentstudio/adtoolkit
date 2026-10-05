
**Decision**: `fitInfo`'s `.ok`/`.warn` text shows the on-disk size
(`gbString(diskBytes)`), while `verdict`'s block reason and
`footprintDescription` show the *estimated* resident size
(`gbString(estimatedBytes)`).
**Rationale**: Per the source's own doc comment, `footprintDescription` is
"computed from ESTIMATED resident bytes" and is reserved for the paths that
need the safety-margin number (a block refusal, or a warn-tier log line);
`fitInfo`'s ok/warn text instead shows the number the user already sees
reported for the model on disk, since the estimate is only needed to decide
*whether* to warn, not to relabel a model that already fits comfortably.
**Approved**: pending

**Decision**: `verdict`'s `warnPct`/`blockPct` parameters carry no default
value, while the equivalent parameters on `tier`, `fitInfo`, and
`pickerLabel` default to `defaultWarnPct`/`defaultBlockPct`.
**Rationale**: `verdict` is the inference-time gate, called by
`LocalInferenceGuard` with a live settings reader that always resolves
`ai_guard_warn_pct`/`ai_guard_block_pct`, so it is written to force every
caller to make that threshold resolution explicit; the labeling-only
functions are used by pickers that may have no override UI (per `fitInfo`'s
own doc comment, "stenographer has no override UI yet, so it relies on the
defaults") and so fall back silently.
**Approved**: pending

**Decision**: `tier` uses `>=` for both the warn and block comparisons, so a
model whose estimated footprint is exactly `warnPct`% of RAM is `.warn`, not
`.ok`, and exactly `blockPct`% is `.block`, not `.warn`.
**Rationale**: This is the plain reading of
`if pct >= Double(blockPct) { return .block }` followed by
`if pct >= Double(warnPct) { return .warn }`; no comment
explains the choice, but it means the threshold value itself is the first
percentage point treated as the more severe tier — the recipe records this
as the normative `tier-classification` boundary rather than leaving a reader
to assume a strict `>`.
**Approved**: pending

**Decision**: In the Swift implementation, `ModelFitPolicy` declares no
`Sendable` conformance of its own, unlike `MemoryPressureLevel`, `Tier`,
`Verdict`, and `FitInfo`, which each are.
**Rationale**: A case-less enum used purely as a namespace for `static`
members has no instances that could ever cross an isolation boundary, so
`Sendable` conformance is not meaningful for it; the four nested/sibling
types that do carry values across boundaries — as parameters or return
values of `ModelFitPolicy`'s functions — are exactly the ones marked
`Sendable`. This is a Swift-specific decision: it applies wherever the
policy is expressed as a namespace of static members in a language with an
explicit cross-isolation-safety marker; a port that models the policy as a
plain module of functions (Compose, React/Web) or a static class (WinUI 3)
has no equivalent conformance to omit or declare.
**Approved**: pending

