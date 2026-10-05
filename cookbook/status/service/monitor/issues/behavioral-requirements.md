
### Reading the Ledger

- **open-issues-grouped-by-target**: Reading the ledger MUST call the storage port's list-open operation once and return a map from target to its list of open rows, in which every returned row appears exactly once, keyed by its own target field.
- **open-issues-oldest-first**: For a given target, the list of open rows this read returns MUST preserve the order the storage port's list-open operation produced (oldest onset time, then row identity, per that operation's own contract) — so the first element of each list is always the canonical row.
- **open-issues-preserves-duplicates**: Reading the ledger MUST NOT deduplicate, drop, or merge rows that share a target, even though a partial unique index is meant to guarantee at most one open row per target. That index has been violated in practice (pre-migration rows, manual backfills), and dropping the extras is exactly what let a shadow row rot: never updated, never resolved, invisible to the very repair cycle whose job it is to close it.
- **single-open-snapshot-per-apply**: Applying the board to the ledger MUST read the ledger exactly once per invocation and decide every target's open/update/resolve action against that one snapshot, never issuing a second ledger read mid-run.

### Data Shapes

- **open-input-shape**: An open-input value MUST carry exactly these fields: target (string), source (an issue source), name (string), environment (string or absent), severity (string), state (string), status code (number or absent), detail (string or absent), source URL (string or absent), live URL (string or absent), plus the optional commit hash, commit message, and commit repository (each string or absent). The three commit fields are the ones a deploy-failure issue carries; the `http`/`dns`/`stale` sources omit them, so they default to absent on that value rather than being required.
- **apply-board-to-ledger-return-shape**: Applying the board to the ledger MUST resolve to exactly an opened count, an updated count, a resolved count, and a list of resolved targets, with no additional or missing fields.

### Opening a New Problem

- **insert-on-absent-open-row**: For each target and its problem in the board's problems, when the ledger snapshot yields no rows for that target, applying the board to the ledger MUST call the storage port's insert primitive with an open-input value built from the problem's target, source, name, environment, severity, state, status code, detail, source URL, live URL, commit hash, commit message, and commit repository — copied verbatim, never re-derived — and MUST increment the returned opened count only after that call resolves without throwing.
- **insert-relies-on-conflict-guard**: The open operation MUST call the storage port's insert primitive without first checking whether an open row already exists for that target; the insert primitive itself guards the partial unique index against a race (an insert-or-do-nothing guarantee), so the race guard is the storage primitive's responsibility, not a check this module duplicates.
- **open-alerts-unconditionally**: The open operation MUST queue an alert with kind `'opened'` every time the insert primitive resolves without throwing, unconditionally — never gated on whether alert delivery is currently configured (that decision belongs to the flush operation, external to this module).
- **open-alert-fields-from-input**: The `opened` alert the open operation queues MUST carry target, name, environment, state, and detail copied from the same open-input value just inserted, never re-read from storage after the insert.

### Refreshing an Open Row

- **update-on-existing-open-row**: When the ledger snapshot yields at least one row for a target, applying the board to the ledger MUST call the storage port's update primitive on the canonical row's identity — never the insert primitive — passing the problem's source, name, environment, severity, state, status code, detail, source URL, and live URL verbatim. This includes refreshing environment and name even though neither is part of the row's identity: both are derived from the roster entry and the deploy row, so a row opened under a stale derivation must not keep the wrong tier badge or an upstream-renamed project's old name for as long as it stays open.
- **update-commit-fields-default-null**: The update primitive MUST receive the commit hash, commit message, and commit repository each coerced to an explicit absent value rather than left unset — an unset commit field on the current problem MUST be written as an explicit absent value, never left unset, on every refresh of an open row (the update-input shape requires all three explicitly; the open-input shape makes them optional).
- **update-never-touches-resolution**: The update path MUST NOT call the storage port's resolve primitive and MUST NOT change the row's onset time; a target that keeps matching a problem across cycles is refreshed in place on its original row, never closed and reopened.
- **update-does-not-alert**: The update path MUST NOT queue an alert; refreshing an open row's derived fields is not a state transition and MUST NOT page on-call.

### Shadow Row Repair

- **close-shadows-targets-non-canonical-rows**: The shadow-repair operation MUST iterate every row except the canonical (first) row only, leaving the canonical row completely untouched by this operation.
- **shadow-resolution-reason-duplicate**: For each row the shadow-repair operation retires, it MUST call the resolve primitive with reason `"duplicate"`.
- **duplicate-resolution-silent**: Because the resolve path only queues an alert when its reason argument is `"recovered"`, retiring a shadow with reason `"duplicate"` MUST NOT queue any alert.
- **shadow-retirement-logged**: For each shadow row it retires, the shadow-repair operation MUST log a warning with exactly the message `` `[ledger] retired duplicate open issue #${dup.id} for ${dup.target} — uniq_open_issue_per_target should have prevented it` ``.
- **shadows-closed-on-both-ledger-paths**: Applying the board to the ledger MUST call the shadow-repair operation for a target's full row list on both the still-flagged path (immediately after the update primitive) and the no-longer-flagged path (immediately after the canonical row's resolve) — a shadow is stale either way, since only the canonical row is ever updated or resolved by the other paths.

### Resolving a Stale Target

- **stale-defined-by-absence-from-live**: Applying the board to the ledger MUST treat a target as stale when it has at least one open row and is NOT among the targets the board currently flags — regardless of whether that target still appears in the board's monitored targets.
- **resolve-reason-by-watched-membership**: For a stale target's canonical row, applying the board to the ledger MUST resolve it with reason `"recovered"` when the target IS a member of the board's monitored targets, and with reason `"unmonitored"` when it is NOT — `"recovered"` means the thing being watched came back, while `"unmonitored"` means monitoring itself stopped (a token removed, a project un-wired), and conflating the two would tell on-call an outage cleared when it may still be burning.
- **resolve-alerts-only-on-recovery**: The resolve path MUST queue an alert with kind `'resolved'` only when its reason argument is `"recovered"`; for `"unmonitored"` or `"duplicate"` it MUST return without queuing any alert.
- **resolve-compares-full-target-string**: Staleness and watched-membership MUST both be decided by comparing the complete target string — never a sub-segment of it. An earlier, now-removed check compared only the project segment of a deploy target, so a target whose environment left config survived every sweep and stayed open forever; comparing the whole string is what fixes that.
- **resolve-skips-target-with-no-open-row**: When a stale target yields no open rows, applying the board to the ledger MUST skip it before entering the write-isolating boundary — no write is attempted and no failure is logged for it.

### Fail-Soft Isolation and Reporting

- **per-target-write-isolation**: For both the still-flagged loop (open/update) and the stale loop (resolve), a thrown error from any storage call for one target's iteration MUST be caught within that same iteration's isolation boundary and MUST NOT prevent applying the board to the ledger from processing every other target. An exception escaping this operation would propagate past the monitor cycle's own cleanup step, skipping peer collection, telemetry collection, and the maintenance store's retention prune and heartbeat ping — and retention pruning silently stopping is what previously drove the per-tick cost past the container's CPU quota.
- **write-failure-log-format**: A caught write failure MUST be reported via the failure-logging helper, which MUST log an error with exactly the message `` `[ledger] write failed for ${target} — skipped, the next cycle re-derives it: ${err instanceof Error ? err.message : String(err)}` ``.
- **counts-reflect-landed-writes-only**: The opened, updated, and resolved counts, and the resolved-targets list, MUST reflect only writes that completed without throwing — a caught failure for a target MUST NOT be counted as opened, updated, or resolved, and MUST NOT add that target to the resolved-targets list.
- **updated-requires-shadow-closure-success**: Applying the board to the ledger MUST increment the updated count for a target only after BOTH the update primitive and the subsequent shadow-repair call for that target complete without throwing — because the updated count is incremented after the shadow-repair call in evaluation order, a shadow-repair failure following a successful update MUST cause that target's updated count to be omitted and MUST cause the failure-logging helper to log for it, even though the canonical row's update already committed to storage.
- **resolved-targets-recorded-before-shadow-closure**: Applying the board to the ledger MUST add a stale target to the resolved-targets list immediately after its canonical row's resolve call succeeds and BEFORE calling the shadow-repair operation for that target. Because that addition happens before the shadow-repair call in evaluation order, a subsequent shadow-repair failure for the same target MUST NOT remove it from the resolved-targets list or from the resolved count, even though the failure-logging helper still logs a write failure for that target — unlike the updated count above, whose accounting is the opposite way around.

### Determinism

- **reapply-is-idempotent**: Invoking the apply operation twice in succession with an unchanged board (the same problems and monitored targets) MUST return an opened count of `0` on the second call and MUST leave the ledger's row count unchanged, because the target already has a matching open row that the second call only refreshes.
- **no-injected-clock**: The apply operation and the ledger read MUST NOT accept a caller-supplied clock parameter; every timestamp either operation's underlying storage primitives write MUST come from that primitive's own current-time reading at the moment it runs. The rule requiring an injectable clock applies to the board-derivation logic, which must be pure for the regression suite — this operation is the opposite kind, one that exists to write rows, and giving it a caller-supplied time it cannot hand to any of its three primitives would document a guarantee it does not make.

### Concurrency

- **concurrent-write-ordering**: The open operation's insert MUST be guarded against concurrent races by the database's partial unique index (insert-or-do-nothing). The update and resolve primitives carry no equivalent guard: no compare-and-swap, version check or transaction ties a target's read to its later write, so overlapping board reconciliations on the same target's open row resolve by last write wins.

