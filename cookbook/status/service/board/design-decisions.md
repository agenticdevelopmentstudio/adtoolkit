
- **Decision**: keep `deployProblems`' concluded and in-flight deploy lists
  separate, and judge a retry's in-flight row only for `stuck`, rather
  than collapsing both lists to one "latest row per target" before
  judging.
  **Rationale**: the source comment states this directly — collapsing was
  the regression this code replaces: a retry's `BUILDING` row would win,
  the target would look neither failed nor stuck, `applyBoardToLedger`
  would read the resulting silence as a recovery, and on-call would be
  paged that a build passed while production still served the broken one.
  **Approved**: pending
- **Decision**: mint a deployment's Activity row ids from only its
  immutable provider id and lifecycle step
  (`deploy:<deploymentId>:<step>`), never from its target, timestamp,
  branch, or project name.
  **Rationale**: the source comment explains that `created_at`, `branch`,
  and `project_name` are all corrected in place by `upsertDeployments`; an
  id built from any of them would mint a second id for the same
  deployment once corrected, and the client's `useActivityHistory` keeps
  an id that leaves the live window forever — the "several sites stuck on
  building hours after they went green" defect the comment describes.
  **Approved**: pending
- **Decision**: derive `Board.dataAsOfMs` from only health-check
  (`checkedAtMs`) and platform-sample (`sampledAtMs`) observations,
  explicitly excluding deploy facts, ledger entries, and stale-prod facts.
  **Rationale**: the source comment explains each exclusion is deliberate
  — a deploy row carries the provider's own clock and can be written by a
  webhook on the API thread while the monitor process is wedged, which
  would refresh this clock without a monitor cycle having run; the ledger
  is the board's own output, so counting it would let the board's writes
  certify its own freshness; `staleProd` carries no observation timestamp
  at all. Every exclusion is chosen so the clock can only read older than
  reality, never fresher.
  **Approved**: pending
- **Decision**: suppress an issue-opened Activity row for a target only
  when the feed already carries a *bad-toned* deploy row for that target
  — never a not-bad (`built`/`deploying`) one.
  **Rationale**: the source comment (labeled "FIX 1" in the regression
  suite) states that a not-bad deploy row says the opposite of a `stale`
  or `stuck` issue on the same target, so it must not be allowed to
  silence the issue that is reporting the actual problem.
  **Approved**: pending
- **Decision**: freeze `errorProblems`' recency test — judging
  already-counted issues indefinitely rather than letting them age out —
  while GlitchTip's own platform-health fact is `configured` and not
  `ok`.
  **Rationale**: the source comment explains the alternative directly: a
  failed GlitchTip poll persists nothing, so every row's `lastSeen`
  simply stops advancing; without the freeze, exactly `ERROR_RECENT_MS`
  after the outage began every error row would silently expire and
  `applyBoardToLedger` would close the open row as `"recovered"` — an
  all-clear page for errors nobody has been able to observe for a day.
  **Approved**: pending

