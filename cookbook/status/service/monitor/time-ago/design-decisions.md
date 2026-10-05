
- **Decision**: use a single `diffSecs < 60` comparison for the just-now bucket rather than
  additionally checking `diffSecs >= 0`, so any negative `diffSecs` (an `iso` timestamp that
  is later than `nowMs`) also formats as `'just now'` rather than being rejected or given a
  distinct label.
  **Rationale**: not stated in source; recorded here as a fact of the code per this
  recipe's authoring rules. Both real callers derive `iso` from a timestamp that has
  already happened relative to their own `nowMs`, so a negative `diffSecs` does not
  currently surface in practice, but nothing in the function itself prevents it.
  **Approved**: pending
- **Decision**: cap output granularity at four buckets — just now, minutes, hours, days —
  with no week/month/year unit and no upper bound on how large the day count can grow.
  **Rationale**: not stated in source; the compact single-value format matches the
  space-constrained detail lines it feeds (`"last {ageLabel} ago"`, `"live build {age}
  old"`), where the values in practice describe recent health-check and deploy activity
  rather than long-past archival timestamps, but the source itself imposes no bound on the
  days figure.
  **Approved**: pending
- **Decision**: return the bucket value with no `"ago"` suffix or unit-name pluralization,
  leaving sentence composition entirely to the caller.
  **Rationale**: demonstrated by both call sites, which each append their own wording
  around the returned value (`"last {ageLabel} ago"` in `integrations.ts`, `"live build
  {age} old"` in `fetch-vercel-projects.ts`) rather than expecting `timeAgo` to produce a
  complete sentence; keeping the function's output caller-composed lets each caller choose
  its own surrounding wording.
  **Approved**: pending

