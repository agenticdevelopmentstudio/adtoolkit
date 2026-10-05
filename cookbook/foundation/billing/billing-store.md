---
id: 4DF278A3-4897-4A87-A506-BD3F58DB3121
title: "Billing Store"
domain: adtoolkit://cookbook/foundation/billing/billing-store
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The business rules for clients, projects and repos, claim resolution, and the per-session derivation unit of work."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - rules
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-persistence
  - adtoolkit://cookbook/foundation/billing/billing-rate
  - adtoolkit://cookbook/foundation/billing/billing-derivation
  - adtoolkit://cookbook/foundation/billing/billing-activity-cache
  - adtoolkit://cookbook/foundation/billing/billing-timer
references: []
approved-by: ""
approved-date: ""
---

# Billing Store

## Overview

Decides what is allowed and what the stored values should be for the billing tables; storage is the host's persistence contract. It saves and deletes clients, projects and repos with validation (names, uniqueness, rounding and rate ranges, unique repo claims, protected history), resolves which repo and project claim a piece of work and whether it is tracked, and derives one session's runs and persists them. The session is the unit of derivation because that is what the watermark is stamped on, so a failure leaves each session fully derived or untouched. Refusals are sentences meant to be shown to the user.

## Behavioral Requirements

- **save-assigns-id-stamps**: A save with an empty id MUST insert with a fresh id; a save with an id MUST update. The stored record MUST be returned with its assigned id and stamps, keeping the original creation time of an existing record.
- **name-required**: A client or project name MUST be trimmed and MUST NOT be empty (`missingName`).
- **name-unique**: A client or project name MUST NOT collide (by the shared unique-name comparison) with any other record of the same kind, archived included (`duplicateName`).
- **project-rounding-range**: A project's rounding minutes MUST be inside 1 to 240; otherwise the save MUST be refused (`invalidRounding`), not clamped.
- **rate-range**: A project's or repo's rate, when present, MUST be inside 0 to 10,000,000 cents; otherwise the save MUST be refused (`invalidRate`).
- **project-client-dangling**: A project whose client id no longer resolves MUST be stored with no client rather than a dangling id.
- **repo-root-required**: A repo's root MUST be trimmed and non-empty (`missingRepoRoot`), and its project MUST exist (`unknownProject`).
- **repo-unique-claim**: A (root, branch) pair, both trimmed, MUST NOT be claimed by another repo row (`repoAlreadyClaimed`).
- **client-delete-guard**: Deleting a client MUST be refused when it has billed or paid entries (`clientHasBilledEntries`); the count and the delete MUST share one transaction.
- **project-delete-guard**: Deleting a project MUST be refused when it has any entry (`projectHasEntries`); the count and the delete MUST share one transaction.
- **resolve-claim**: `resolveRate` MUST return the repo and project that claim a root and branch over the live tables, archived projects included.
- **tracked-flag**: Work MUST be tracked only when both the claiming repo row and its project have billing enabled; Unassigned work has no switch and is tracked.
- **derive-session**: `deriveSegments` MUST resolve the claim, read the session's activity through the cache, derive runs, replace the session's derived segments with the claim, tracked flag, current zone and history start, stamp the watermark with the value read at selection time, and return how many segments were written.
- **unassigned-still-written**: Unassigned work MUST still be written when unassigned tracking is on.
- **unassigned-opt-out**: With unassigned tracking off and no claiming project, `deriveSegments` MUST write nothing new, MUST close the session's open derived runs, MUST stamp the watermark, and MUST return 0.
- **close-open-runs**: Closing an open run MUST end it where the matching run ends when the session is treated as finished, or at its own start with zero seconds when no run covers it.
- **refusals-are-sentences**: Every refusal MUST present a sentence fit to show the user.

## Appearance

Not applicable — this is a non-visual rules service, not a visual component.

## States

Not applicable — this is a non-visual rules service, not a visual component.

## Accessibility

Not applicable — this is a non-visual rules service, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-store-001 | name-required | save client named `"  "` | throws `missingName` |
| billing-store-002 | name-unique | save project `Site` when another `Site` exists | throws `duplicateName("Site")` |
| billing-store-003 | project-rounding-range | save project with rounding 0 | throws `invalidRounding(0)` |
| billing-store-004 | project-rounding-range | save project with rounding 241 | throws `invalidRounding(241)` |
| billing-store-005 | rate-range | save repo with rate -1 | throws `invalidRate(-1)` |
| billing-store-006 | repo-unique-claim | second repo for the same root and branch | throws `repoAlreadyClaimed` |
| billing-store-007 | project-client-dangling | project with client id `gone` | stored with no client |
| billing-store-008 | save-assigns-id-stamps | save with empty id | stored id non-empty; created = updated |
| billing-store-009 | project-delete-guard | project with 1 entry | throws `projectHasEntries(count: 1)` |
| billing-store-010 | client-delete-guard | client with 2 billed entries | throws `clientHasBilledEntries(count: 2)` |
| billing-store-011 | tracked-flag | repo billing off | `tracked` false |
| billing-store-012 | unassigned-opt-out | unclaimed repo, unassigned tracking off | returns 0; open runs closed; watermark stamped |

## Edge Cases

- Duplicate-name and repo-claim checks read and then write without a shared transaction, so two concurrent saves can both pass the check; the host's unique index is the backstop for repos, and nothing backstops names.
- A zero-length or malformed session start is handled by derivation.
- An error mid-derivation propagates before the watermark is stamped, so the session is re-derived next pass.
- Deleting a repo has no precondition.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| trackUnassigned | boolean | true | Whether work in a repo no project claims is recorded. |
| cutoffSeconds | integer | from preferences | Idle gap passed to derivation. |
| activity | activity cache | a fresh cache per call | Cache of session activity; the long-lived task supplies its own. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Refusal sentences such as "Rounding must be at least one minute" and "Another one is already called" are hardcoded English strings produced from `errorDescription`, not routed through a string catalog.

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
- **Compose**: A service object over the persistence interface; refusals as a sealed class.
- **React/Web**: A module of async functions over a repository; refusals as typed `Error` subclasses.
- **AppKit / UIKit**: A Foundation-only enum namespace of static functions; refusals as `BillingError: LocalizedError`.
- **WinUI 3**: A static or injected service over an interface; refusals as exception types with a user-facing `Message`; wrap check-and-delete in a `SqliteTransaction`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingStore.swift` |

## Design Decisions

**Decision**: Duplicate-name checks are not atomic with the write.
**Rationale**: The check reads other records and then upserts outside one transaction; making it atomic needs the check inside `transaction`, and a unique index on the normalized name to back it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: validation and derivation orchestration live here while storage is the persistence contract and rate resolution, rounding and derivation are their own types. unit-test-coverage fails: only `BillingRate` (via `BillingRateResolutionTests`) is tested directly; no test in `AgenticToolkitCoreTests/Billing` calls `BillingStore` save, delete or `deriveSegments`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
