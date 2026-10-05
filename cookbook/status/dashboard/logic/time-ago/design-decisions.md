
- **Decision**: take `nowMs` as a parameter rather than reading the clock.
  **Rationale**: the doc comment says it is "passed in for testability"; it also lets
  callers share one `useNow` tick so labels stay stable between re-renders.
  **Approved**: pending
- **Decision**: a single `diffSecs < 60` test with no `>= 0` check, so future timestamps
  show `just now`.
  **Rationale**: not stated in source; recorded as a fact. It hides server/browser clock
  skew instead of showing a negative age.
  **Approved**: pending
- **Decision**: four buckets with no unit above days and no `ago` suffix.
  **Rationale**: the compact token fits the dense dashboard cells it feeds, and callers
  such as `Dashboard` and `ProjectBrowser` add their own wording.
  **Approved**: pending
- **Decision**: duplicate the function in status-web and status-server instead of sharing
  one module.
  **Rationale**: not stated in source; the two packages are deployed separately. A port
  must keep the two copies' behavior identical.
  **Approved**: pending

