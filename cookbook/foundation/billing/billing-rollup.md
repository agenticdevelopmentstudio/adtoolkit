---
id: A252605D-12CE-4235-9EB4-2582678F6F49
title: "Billing Rollup"
domain: adtoolkit://cookbook/foundation/billing/billing-rollup
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Turns closed, assigned segments into billing entries, recomputes entries the rollup owns, and owns every entry edit, status move, delete and overview."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - rollup
  - entries
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-rate
  - adtoolkit://cookbook/foundation/billing/billing-rounding
  - adtoolkit://cookbook/foundation/billing/billing-clock
  - adtoolkit://cookbook/foundation/billing/billing-persistence
  - adtoolkit://cookbook/foundation/billing/billing-store
references: []
approved-by: ""
approved-date: ""
---

# Billing Rollup

## Overview

Rolls closed segments into billing entries under one rule: an entry at `unbilled` is a view of its segments and may be recomputed on every pass; an entry past `unbilled` is history and is never recomputed, edited or silently grown. Late work on a frozen day becomes a visible supplemental entry. Entries group by project, local day and rate (day granularity) or by run (run granularity), so an entry never mixes two rates. Rate, rounding and currency are snapshotted when the entry is first written, so a later rate change never reprices old time. The same component owns hand edits, description-only edits, deletes, audited status moves, assigning segments, and the per-currency overview.

## Behavioral Requirements

- **rollup-pass**: `run` MUST roll every eligible candidate segment into entries, then recompute the entries the rollup owns (all, or only a given set), and return how many entries were created, recomputed or removed.
- **promote-subset**: `promoteSegments(ids)` MUST roll only the named segments and return 0 for an empty list.
- **slot-grouping**: Candidates MUST group by project, local day (from the segment start and its own zone) and group key; segments without a project MUST be skipped.
- **group-key**: At day granularity the group key MUST be the rate itself (`rate:<cents>`); at run granularity it MUST be the run's stable identity: `<sessionId>|<startedAt>` for an auto segment and the segment id for a manual one.
- **rate-per-segment**: Each segment's rate MUST be resolved by the shared rate ladder with the repo row, project and the global default, and MUST be part of the slot, so one entry never mixes two rates.
- **apply-atomic**: Re-reading the segments, finding the owner, summing what it holds and writing MUST happen in one transaction, and only segments still unattached, billable and where they were grouped (same project, repo, start and zone) MUST be rolled.
- **frozen-owner-supplement**: If the slot's owner is locked or has origin `user`, new time MUST go to that entry's open supplement (created if none) and the owner MUST NOT change.
- **legacy-slot**: A day entry stored with an empty group key MUST still own time at its own rate and be re-keyed when next written.
- **snapshot-figures**: A new entry MUST snapshot the rate, rounding minutes (default 15), rounding mode (default `up`) and currency; an existing entry MUST keep its own snapshot. Currency MUST come from the project's client when set, else the global currency.
- **figures**: Raw seconds MUST be the sum of segment seconds; billed seconds MUST be rounded once over that total; the amount MUST be the shared money arithmetic over billed seconds and rate; start MUST be the earliest segment start and end the latest segment end.
- **description**: The description MUST join session titles, distinct trimmed notes, and `on <branches>` with `; `, unless the description was hand edited, in which case it MUST be kept.
- **rollup-owned-only**: Recompute MUST touch only entries that are unlocked with origin `auto`; each MUST be re-read and rewritten in one transaction and written only when figures or description changed.
- **empty-entry-removed**: A recomputed entry left with no segments MUST be deleted unless a supplement still points at it (the persistence layer then keeps it at zero).
- **save-entry-origin**: `saveEntry` MUST store a new entry, or an edit that changes a figure (project, day, times, seconds, rate, currency, amount, rounding), with origin `user`; a description-only edit MUST keep the origin and mark the description edited.
- **save-entry-refusals**: `saveEntry` MUST refuse a locked entry (`entryIsLocked`), a changed status (`statusChangeNotAllowed`), and a stale save whose `updatedAt` or raw seconds differ from the stored row (`entryChanged`).
- **set-description**: `setDescription` MUST trim the text, change only the description, refuse a missing entry (`unknownEntry`) or a locked one (`entryIsLocked`), and return the stored row.
- **delete-entry**: `deleteEntry` MUST refuse a missing entry, a locked entry, and an entry with a billed, paid or hand-edited supplement (`entryHasFrozenSupplements`).
- **set-status**: `setStatus` MUST be the only way status changes, MUST lock the entry for billed and paid states, MUST write an audit row (field `status`, old, new, source) for every actual change including moves backward, and MUST return the existing row unchanged when the status is already that value.
- **assign-repository**: `assignRepository` MUST return 0 for an empty root; otherwise move every unassigned segment of that root into the project and promote them, returning how many moved.
- **overview**: `overview` MUST return one row per currency with unbilled, billed and paid buckets (empty buckets when absent), MUST never sum across currencies, and MUST set the top-level figures from the first row (default currency `USD` when there are none).
- **money**: `amountCents` MUST be whole cents, rounded half-up, by the shared money arithmetic.

## Appearance

Not applicable — this is a non-visual rules service, not a visual component.

## States

Not applicable — this is a non-visual rules service, not a visual component.

## Accessibility

Not applicable — this is a non-visual rules service, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rollup-001 | group-key | day granularity, rate 12000 | group key `rate:12000` |
| billing-rollup-002 | group-key | run granularity, auto segment session s1 starting 2026-09-22T14:00:00Z | `s1|2026-09-22T14:00:00Z` |
| billing-rollup-003 | figures | segments of 300 s five times, rounding 15 `up` | raw 1500, billed 1800 |
| billing-rollup-004 | figures | billed 5400 s at 12000 cents per hour | amount 18000 |
| billing-rollup-005 | frozen-owner-supplement | owner billed, new segment same slot | new supplement entry pointing at the owner; owner unchanged |
| billing-rollup-006 | snapshot-figures | project default rate changes after entry written, then recompute | entry keeps its original rate |
| billing-rollup-007 | rollup-owned-only | locked entry | not recomputed |
| billing-rollup-008 | empty-entry-removed | auto entry whose segments were detached | entry deleted |
| billing-rollup-009 | save-entry-origin | edit changing only the description of an auto entry | origin stays `auto`; description marked edited |
| billing-rollup-010 | save-entry-origin | edit changing hours | origin `user` |
| billing-rollup-011 | save-entry-refusals | save with different `updatedAt` | throws `entryChanged` |
| billing-rollup-012 | save-entry-refusals | save of locked entry | throws `entryIsLocked` |
| billing-rollup-013 | set-status | unbilled to billed | entry locked; audit row (`status`, `unbilled`, `billed`) |
| billing-rollup-014 | set-status | billed to unbilled | entry unlocked; audit row written |
| billing-rollup-015 | delete-entry | entry with a billed supplement | throws `entryHasFrozenSupplements` |
| billing-rollup-016 | overview | USD and EUR entries | two currency rows; top-level is the first |
| billing-rollup-017 | assign-repository | empty root | returns 0 |

## Edge Cases

- Segments with no project are skipped by the roll and stay unassigned.
- Parallel overlapping sessions can make a later-starting segment end earlier; the entry end is the maximum end, not the last segment's end.
- A `setStatus` to the same status is a no-op and writes no audit row.
- `assignRepository` assigns and promotes in separate calls, so a failure in promotion leaves segments assigned but not yet rolled; the next pass rolls them.
- An overview with no entries reports zero buckets in `USD`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| options.granularity | `day` or `run` | `day` | How entries group; changeable at any time, affecting only later passes. |
| options.defaultRateCents | integer | 0 | Used only when neither repo nor project names a rate. |
| options.currency | ISO 4217 code | `USD` | Used when the project has no client currency. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Refusal sentences for a changed entry and for frozen supplements, and the description fragment `on <branches>`, are hardcoded English strings; shared refusal text is also fixed English.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the service has no view layer.
- **Compose**: A service over the persistence interface with a sealed result for refusals.
- **React/Web**: A module of async functions over a repository; wrap each slot in one transaction.
- **AppKit / UIKit**: A Foundation-only enum namespace; refusals as `RollupError: LocalizedError`; `UUID().uuidString` for ids.
- **WinUI 3**: A static or injected service; wrap each slot in a `SqliteTransaction`; use `Guid.NewGuid()` and `decimal`-free integer cents.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingRollup.swift` |

## Design Decisions

**Decision**: A repository assignment and its promotion are two separate calls rather than one transaction.
**Rationale**: If promotion fails after assignment, segments are assigned but not yet rolled; the next scheduled pass rolls them, so it self-heals. Making it atomic would wrap both in one transaction.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: rolling and entry rules live here while storage is the persistence contract, and rate, rounding, money and the local-day rule are shared types. unit-test-coverage fails: no test in `AgenticToolkitCoreTests/Billing` calls `BillingRollup`; `BillingRoundingTests` and `BillingRateResolutionTests` cover only its collaborators.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
