---
id: 01942F60-6711-43E7-A7B2-A8E7CB4C2CDA
title: "Billing Model"
domain: adtoolkit://cookbook/foundation/billing/billing-model
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Always-running billing state for an app: cached lists, a polling refresh, consumer-aware reads, and writes that refresh so every consumer sees them."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - state
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-xpc-client
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
  - adtoolkit://cookbook/foundation/billing/billing-editing
references: []
approved-by: ""
approved-date: ""
---

# Billing Model

## Overview

Holds the latest billing state (clients, projects, running timers, recent segments, the overview, the last error, the last-updated time) and publishes a change signal. Views are consumers: they subscribe to the signal, read the state, and write only through the model's methods, each of which refreshes, so an edit in one window reaches every other. It is written against a billing service interface, so a host supplies an IPC client or a test fake. State is sticky through failure: a failed refresh sets the error and keeps the last good lists. Polling is cheap when nothing is on screen: only the running timers are read. A write that starts while a refresh is reading makes that refresh drop its answers, so a stale read never rolls a write back on screen.

## Behavioral Requirements

- **cached-state**: The model MUST expose clients, projects, running timers, recent segments (last 14 days, at most 500), the overview, `lastError` and `lastUpdated`, and MUST publish a change signal whenever visible state changes.
- **refresh-all**: `refresh` MUST read clients, projects, running timers, recent segments and the overview concurrently, and replace the cached state only when the first four succeeded.
- **sticky-failure**: If any of the four required reads fails, the model MUST keep the last good lists, set `lastError` to the unreachable sentence, and signal only when the error is new or the caller asked to be told of unchanged results.
- **overview-fails-alone**: A failed overview read MUST keep the last good overview and MUST NOT count as a failed refresh.
- **quiet-when-unchanged**: A poll that finds nothing changed MUST NOT signal; an explicit refresh MUST signal.
- **write-generation**: A refresh MUST discard its answers if any write began while it was reading; the write's own refresh follows.
- **writes-refresh**: Every write (save and delete of clients, projects, repos, entries; set status; set description; start and stop timer; promote; assign; backfill) MUST be followed by a refresh.
- **refusal-in-last-error**: A refused write MUST return nil (or false for a delete) and leave the refusal sentence in `lastError` after the refresh, which would otherwise clear it.
- **success-clears-error**: A successful refresh MUST clear `lastError`.
- **consumer-aware-poll**: A scheduled poll MUST read everything when any consumer reports it is showing (and always on the first pass), and otherwise read only the running timers.
- **consumer-lifetime**: A consumer registration MUST be dropped when its owner is released or it is removed explicitly.
- **consumer-shown**: When a consumer is shown and the data is older than the interval, the model MUST refresh at once.
- **assign-and-roll**: `assignAndRoll` MUST assign the segments, then promote them with one refresh; when the assignment moves nothing for a non-empty list it MUST set `lastError` to the already-on-a-billable sentence and return nil.
- **refresh-interval**: The poll interval MUST default to 30 seconds.
- **lookups**: `projectName(for:)` MUST return the project's display title or `Unassigned` when none; `activeSorted` MUST drop archived projects and sort by display title using the localized standard comparison.
- **timestamps**: `date(iso:)` MUST parse an ISO-8601 UTC instant with or without fractional seconds and return nil for an empty string.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable — this is a non-visual state holder, not a visual component.

## States

Not applicable — this is a non-visual state holder, not a visual component.

## Accessibility

Not applicable — this is a non-visual state holder, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-model-001 | sticky-failure | all reads succeed, then the clients read fails | lists unchanged; `lastError` is the unreachable sentence |
| billing-model-002 | overview-fails-alone | overview read fails, other reads succeed | lists updated; previous overview kept; `lastError` nil |
| billing-model-003 | refusal-in-last-error | save of a project refused with "A name is required." | returns nil; `lastError` is that sentence |
| billing-model-004 | success-clears-error | refused write then successful write | `lastError` nil |
| billing-model-005 | consumer-aware-poll | no consumer showing, not first poll | only running timers read |
| billing-model-006 | consumer-aware-poll | a consumer reports showing | all five reads performed |
| billing-model-007 | quiet-when-unchanged | poll with identical data | no change signal |
| billing-model-008 | write-generation | refresh answered after a write began | answers discarded; state not rolled back |
| billing-model-009 | assign-and-roll | assign moves 0 of 2 requested | returns nil; `lastError` is the already-on-a-billable sentence |
| billing-model-010 | assign-and-roll | assign moves 2, promote rolls 2 | returns 2; one refresh |
| billing-model-011 | lookups | segment with no project | `Unassigned` |
| billing-model-012 | lookups | archived and active projects `b`, `a` | `a` only active, sorted |
| billing-model-013 | timestamps | `2026-09-22T14:00:00Z` and `2026-09-22T14:00:00.250Z` | both parse |
| billing-model-014 | timestamps | empty string | nil |
| billing-model-015 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- A model that nobody retains is released even if started.
- A failed write of an entry that no longer exists reports that, not "locked".
- Moving an entry to its own status writes no audit.
- A running timer ticks locally between polls; the model supplies only the start instant.
- The first poll reads everything even if no consumer has yet said it is showing, because a window restored at launch is on screen first.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| refreshInterval | seconds | 30 | Poll period; the daemon's own pass runs every minute. |
| recentWindowDays | integer | 14 | How far back the recent-run list reaches. |
| recentSegmentLimit | integer | 500 | Maximum recent segments read. |
| service | billing service | required | Where every read and write goes. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

The `Unassigned` title and the already-on-a-billable sentence are hardcoded English strings.

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

- **SwiftUI**: A view observes the change signal (for example through an `ObservableObject` bridge); the model itself imports no SwiftUI.
- **Compose**: A `ViewModel` exposing `StateFlow`s with a polling coroutine; `async` reads via `async`/`await`.
- **React/Web**: A store (for example a reducer or a signal-based class) with a polling timer; use `Promise.all` for the concurrent reads.
- **AppKit / UIKit**: A `@MainActor final class` publishing through a Combine `PassthroughSubject<Void, Never>`; reads use `async let`; the poll is a `PeriodicRefresher`.
- **WinUI 3**: A class implementing `INotifyPropertyChanged` with `ObservableCollection` lists; poll with `PeriodicTimer` and read concurrently with `Task.WhenAll`; marshal changes through `DispatcherQueue`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingModel.swift` |

## Design Decisions

**Decision**: Failure sentences and the Unassigned title are fixed English strings.
**Rationale**: The model holds the sentences it shows the user as constants (`Unassigned`, the already-on-a-billable message, the shared refusal text); localizing them would route them through a string catalog.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: the model owns cached state, polling and write sequencing and is written against the service interface, so transport, storage and presentation are elsewhere. unit-test-coverage passes: `BillingModelTests` and `BillingModelAssignmentTests` in `AgenticToolkitCoreTests/Billing` cover refresh, sticky failure, refusals, consumer-aware polling, quiet polls, the write-versus-refresh race, assignment, timers, backfill and date parsing.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
