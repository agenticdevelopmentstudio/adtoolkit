
This is the status backend's board fold: eight files under `src/board/`
that reduce every monitoring fact the status site has — provider deploy
polls and webhooks, HTTP/DNS probes, provider platform-health samples,
GlitchTip error groups, the operator's roster configuration, and the
ledger's open-row onsets — into one `Board` value. `types.ts` defines the
fact and output shapes (`BoardFacts`, `Problem`, `ActivityRow`, `Board`) and
the module's constants. `target-key.ts` mints and parses the one canonical
spelling of a deploy target (`boardTargetKey`/`parseBoardTarget`), with
percent-escaping so the mint-parse round trip is total. `ownership.ts`
resolves which roster entry, if any, owns a deploy row or project
(`matchRosterEntry`, `ownedDeployTarget`, `rosterDeployProjects`), matching
by provider id first and project name second. `derive-problems.ts` judges
the five Problem families (deploy, endpoint, platform, stale-prod, error)
and computes `monitoredTargets`, the authoritative "currently watched" set.
`derive-activity.ts` derives the Activity feed as the union of deploy and
issue events (`deriveActivity`), the overall `indicatorFor`, and the
cursor-paginated `pageActivity`. `derive.ts` is the top-level fold,
`deriveBoard`, that combines all of the above into one `Board`.
`facts.ts` is the fold's read-side orchestration (`readBoardFacts`,
`readActivityPage`, `createActivityPageReader`) — the only file in
`src/board/` that touches `Storage`. `reconcile.ts` is the single
reconciliation entrypoint, `reconcileBoardLedger`, that reads facts, folds
them, writes the ledger diff, and flushes alerts, safe to call repeatedly
and from multiple callers. Every derivation function is pure: `nowMs` is a
parameter, there is no IO, and calling one twice with the same facts gives
a deep-equal result — the property the regression suite in
`test/board-regressions.test.ts` pins directly.

