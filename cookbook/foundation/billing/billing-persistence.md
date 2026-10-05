---
id: 5296D0B7-8416-4E76-8F45-47A726F230CF
title: "Billing Persistence"
domain: adtoolkit://cookbook/foundation/billing/billing-persistence
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The storage contract billing logic runs against: settings, clients, projects, repos, segments, entries and overview queries, plus the row shapes they exchange."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - storage
  - contract
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-store
  - adtoolkit://cookbook/foundation/billing/billing-rollup
  - adtoolkit://cookbook/foundation/billing/billing-timer
  - adtoolkit://cookbook/foundation/billing/billing-prefs
references: []
approved-by: ""
approved-date: ""
---

# Billing Persistence

## Overview

The host supplies storage; every billing rule (who claims a repo, how runs roll into entries, what a locked entry refuses) lives in the shared tier and runs against this contract. It declares the operations over settings and transactions, clients, projects, repos, segments, derivation, entries, assignment and overview, and the small value types they exchange: the session row derivation needs, the context a derived run is attributed to, the guard that decides which existing entry row an upsert may overwrite, and an entry paired with whether its description was hand edited. The store, rollup, timer and preferences logic all take an implementation of this contract.

## Behavioral Requirements

- **settings-and-keys**: The contract MUST expose the host's billing settings key set and read and write string settings by key.
- **transaction-atomic**: `transaction(body)` MUST run `body` as one write transaction: all of its writes land, or none do; an error thrown by `body` MUST roll everything back and propagate.
- **reset-derivation**: `resetBillingDerivationOfDerivedSessions` MUST forget every derived session's watermark so all derived time is re-split on the next pass, and return how many sessions were reset.
- **session-row**: A `BillingSessionRow` MUST carry session id, project root, branch, start instant, the last-activity value to stamp as the watermark once consumed, and whether the session is live.
- **segment-context**: A `BillingSegmentContext` MUST carry project id and repo id (both absent for Unassigned), project root, branch, zone, and a `tracked` flag; when `tracked` is false, time first derived under it MUST be flagged `untracked` and never rolled, even if tracking is later turned on.
- **overwrite-guard**: `upsertBillingEntry(dto, overwrite)` MUST always insert a new id, and for an existing row MUST apply the guard against the row as it is at write time: `any` overwrites any row, `unlocked` only an unlocked row, `rollupOwned` only an unlocked row with origin `auto`. It MUST return whether a row was written, false only when the guard refused.
- **stored-entry**: A `StoredBillingEntry` MUST pair the entry DTO with `descriptionEdited`, which decides whether the rollup may rewrite the description.
- **activity-cursor**: `billingActivitySeconds(sessionId, afterId)` MUST return the session's activity instants (epoch seconds) after the cursor and the cursor to resume from.
- **replace-derived**: `replaceDerivedSegments` MUST replace the session's derived segments with the given runs under the given context and history start, and return how many were written.
- **rollup-candidates**: `billingRollupCandidates(ids)` MUST return closed, unrolled segments of billing-enabled projects, narrowed to `ids` when given.
- **close-and-flag-booleans**: `closeBillingSegment`, `addBillingSegmentFlag`, `deleteEmptyBillingEntry` and `setBillingEntryDescription` MUST return whether a row changed.
- **explicit-arguments**: Every operation MUST be callable with every argument supplied; the contract defines no defaults.
- **overview-buckets**: `billingOverviewBuckets` MUST return, per currency, buckets keyed by status.

## Appearance

Not applicable — this is a storage protocol and its value types, not a visual component.

## States

Not applicable — this is a storage protocol and its value types, not a visual component.

## Accessibility

Not applicable — this is a storage protocol and its value types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-persistence-001 | transaction-atomic | body writes two settings then throws | neither setting is changed; the error reaches the caller |
| billing-persistence-002 | overwrite-guard | upsert of a locked entry with `unlocked` | returns false; the row is unchanged |
| billing-persistence-003 | overwrite-guard | upsert of a user-origin entry with `rollupOwned` | returns false |
| billing-persistence-004 | overwrite-guard | upsert of a new id with any guard | returns true; the row is inserted |
| billing-persistence-005 | activity-cursor | `afterId` 0 for a session with three events | all three instants and the last id |
| billing-persistence-006 | activity-cursor | `afterId` equal to the last id | empty seconds |
| billing-persistence-007 | rollup-candidates | a closed segment of a project with billing off | not returned |
| billing-persistence-008 | segment-context | `tracked` false for a derived run | the segment is stored flagged `untracked` and never appears in rollup candidates |
| billing-persistence-009 | reset-derivation | three derived sessions | returns 3; the next pass re-derives all three |

## Edge Cases

- A read of a missing record returns nil rather than throwing.
- A host that cannot honor `transaction` atomically cannot satisfy the rollup's no-double-count guarantees.
- Deleting a client detaches its projects; deleting a project detaches its segments; both are the host's to implement.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| billingSettingsKeys | key set | host supplied | Where this host stores the eight billing settings. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Everything held through this contract is the user's own business data (clients, rates, hours, notes) stored by the host in its local database; this code transmits nothing.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the contract has no view layer.
- **Compose**: An interface implemented over Room or SQLDelight, with `withTransaction`.
- **React/Web**: A repository interface over IndexedDB or a server API; map `transaction` to one atomic batch.
- **AppKit / UIKit**: A Swift protocol conformed to by the host's SQLite database manager; the type is not `Sendable`, so callers keep it in their own isolation.
- **WinUI 3**: An interface implemented over SQLite (`Microsoft.Data.Sqlite`) with `SqliteTransaction`; implement `transaction` with `BeginTransaction`/`Commit`/`Rollback`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingPersistence.swift` |

## Design Decisions

**Decision**: The contract carries no schema; uniqueness and `NOT NULL` rules live in the host's tables.
**Rationale**: Rules such as the project-day-group unique index and a non-null entry project are named in comments but enforced by the host database; moving them into a shared migration would require a shared schema.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: this is the seam that keeps rules in the shared tier and storage in the host. unit-test-coverage fails: the protocol is a declaration, and a search of the Tests directories finds no type that conforms to `BillingPersistence` and no test that exercises a conforming store's guard or transaction semantics; `BillingModelTests` and `FakeBillingClient` stand in for the billing service, not for this storage contract, and the host's own database tests live outside this repository.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
