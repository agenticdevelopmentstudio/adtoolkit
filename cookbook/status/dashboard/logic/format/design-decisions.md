
**Decision**: One module owns the pluralization, short-sha and commit-subject shapes.
**Rationale**: The header comment says these shapes "were otherwise copy-pasted across the fetchers, row builders, and config surfaces"; one definition keeps the banner, Auto Configure summary and Config badges in agreement on copy.
**Approved**: pending

**Decision**: `shortSha` uses a fixed 7-character prefix.
**Rationale**: The doc comment names "GitHub's 7-char form", matching the abbreviation users see on GitHub.
**Approved**: pending

**Decision**: Empty and missing inputs map to `null` rather than `""` in `shortSha` and `commitFirstLine`.
**Rationale**: The test comment reads "empty → no commit"; `null` lets callers such as `DeployList.tsx` (`shortSha(d.commitHash) ?? ""`) and `row-model.ts` distinguish "no commit" from a value.
**Approved**: pending

**Decision**: `commitFirstLine` truncates hard at 200 characters with no ellipsis.
**Rationale**: The doc comment specifies only a cap at `max`; rows show the subject, and the cap bounds pathological single-line messages. Truncation is silent by design.
**Approved**: pending

**Decision**: `plural` uses the English one/other rule with an optional explicit plural form.
**Rationale**: The dashboard's copy is English-only; the `pluralForm` parameter covers irregular nouns without a locale system.
**Approved**: pending

