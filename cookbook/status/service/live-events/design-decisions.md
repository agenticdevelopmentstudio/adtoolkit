
- **Decision**: anchor the 150ms coalesce window to the *first*
  `emitLiveUpdate` call in a burst, and let every later call in that burst
  return immediately without resetting or extending the timer, rather than
  implementing a conventional trailing-edge debounce that restarts on every
  call.
  **Rationale**: the source comment describes this as "bursts coalesce into
  a single trailing build," meaning the one build that eventually runs
  trails the burst of calls, not that its delay is reset by each new call;
  anchoring to the first call bounds the worst-case added push latency for
  any caller in a burst to exactly 150ms, at the cost that the build reflects
  the `storage`/`config` values captured from the first call, not a later
  one, which is unobserved in this codebase because every call site passes
  the same singleton `storage`/`config`.
  **Approved**: pending
- **Decision**: let `recentSnapshot`'s staleness window (`maxAgeMs`) be
  supplied by the caller on every call rather than fixed as a module
  constant.
  **Rationale**: not stated verbatim in the source comment, but evidenced
  directly by the one real call site in this package — `routes/stream.ts`'s
  `OPENING_CACHE_MS` (1500ms) — which needs a different tolerance than a
  hypothetical stricter consumer; a per-call parameter lets each caller
  choose its own window with no change to this module.
  **Approved**: pending
- **Decision**: never surface a failed build to the code that called
  `emitLiveUpdate`, whether by throwing, rejecting a returned promise (there
  is none — `emitLiveUpdate` returns `void`), or any other signal.
  **Rationale**: the source comment states this directly: a failed build is
  "logged and dropped ... never thrown into the cycle/webhook that called
  us," because `emitLiveUpdate`'s two real callers (a webhook handler in
  `routes/hooks.ts`) already have their own successful side effect to
  respond with (a `200` to the webhook provider), and failing that response
  over a live-push failure would be strictly worse than a delayed push, since
  the next successful build (the next cycle, webhook, or the client's own
  polling fallback) recovers the data anyway.
  **Approved**: pending
- **Decision**: this recipe is intentionally shallower than its sibling
  `Status Server Auth` (7 exported behaviors and roughly 20 requirements here
  versus five files and roughly 40 requirements there).
  **Rationale**: the disparity tracks the components' actual surface area,
  not a difference in authoring effort — `live-events.ts` is one 66-line
  module with six exported functions and no HTTP route or security surface
  of its own, while the auth family spans cookies, an OAuth flow, and
  password hashing across five files; per the Cross-Recipe Consistency
  guideline, a depth disparity this size is warranted by genuinely different
  functional complexity, not a completeness gap in either recipe.
  **Approved**: pending
- **Decision**: record, rather than resolve, a naming mismatch between this
  module's own doc comment and the shared `LiveSnapshot` type it hands
  around.
  **Rationale**: the doc comment describes a client-side reducer advancing
  "count-based provider streaks only when `cycleAt` strictly increases," but
  the field `LiveSnapshot` actually exposes (`monitor/live-types.ts`) is
  named `lastCycleAt`. `live-events.ts` itself never reads or writes that
  field — it hands the whole snapshot through opaquely — so this is a
  terminology drift in a comment describing external client behavior, not a
  defect in this file's own behavior; recorded here per this cookbook's
  Source Fidelity guideline on documenting quirks rather than smoothing them
  over.
  **Approved**: pending

**Decision**: A snapshot build already in flight when live events are reset is not cancelled and can publish after the reset.
**Rationale**: It stands today because no abort signal or generation counter reaches the build. Closing it needs an abort signal threaded into the snapshot builder, or a generation counter checked before the late publish, and a reset-during-build test.
**Approved**: pending

