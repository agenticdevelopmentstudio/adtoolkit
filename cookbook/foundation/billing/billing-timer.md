---
id: F2A31FE2-1302-46D9-8CB4-CC6E9A5E8A12
title: "Billing Timer"
domain: adtoolkit://cookbook/foundation/billing/billing-timer
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Hand-started time: start, stop, stop-all, list and runaway-flagging of manual timers stored as ordinary open segments."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - timer
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-store
  - adtoolkit://cookbook/foundation/billing/billing-persistence
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing Timer

## Overview

A manual timer is a billing segment with origin `manual` and an empty end, the same row shape a derived run uses, so it rolls up, assigns and displays through one code path. The one invariant is that at most one manual timer runs: starting a timer closes any other running timer at the same instant, inside one transaction, because two running timers would bill the same wall-clock minute twice. Derived runs belong to the derivation pass and are never closed by hand. A timer that runs longer than a cap is flagged, never stopped or truncated.

## Behavioral Requirements

- **start-closes-others**: `start` MUST close every other running manual timer at the new timer's start instant and insert the new segment in one transaction; a failed insert MUST leave the previous timers running.
- **start-resolves-project**: When the request names no project and has a non-empty project root, `start` MUST resolve project and repo from the root and branch through the store's claim; when the request names a project it MUST be used unchanged.
- **start-shape**: The new segment MUST have a fresh id, an empty session id, origin `manual`, an empty end, zero seconds, the request's root, branch and note, the start instant `now`, and the current time zone identifier.
- **stop**: `stop(id)` MUST close the segment at `now` with seconds equal to the elapsed time and return the closed segment.
- **stop-unknown**: `stop` of an id that does not exist MUST throw `unknownTimer`.
- **stop-not-running**: `stop` of a segment that is already closed MUST throw `notRunning`.
- **stop-all-manual-only**: `stopAll` MUST close every running manual timer, MUST leave derived runs alone, and MUST return how many it closed.
- **running**: `running` MUST return every running segment of any origin.
- **flag-runaways**: `flagRunaways(capSeconds)` MUST add the flag `runaway` to every running manual timer whose elapsed time exceeds the cap, MUST NOT stop or truncate it, and MUST return how many it newly flagged.
- **cap-non-positive**: A cap of zero or less MUST flag nothing.
- **clock-injected**: Every operation MUST take `now` as a parameter defaulting to the current UTC time so it is testable.
- **errors-are-sentences**: Timer errors MUST present the shared refusal sentences for an unknown timer and a timer not running.

## Appearance

Not applicable — this is a non-visual timer service, not a visual component.

## States

Not applicable — this is a non-visual timer service, not a visual component.

## Accessibility

Not applicable — this is a non-visual timer service, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-timer-001 | start-closes-others | timer A running; start B at `now` | A closed at `now`; B running; one transaction |
| billing-timer-002 | start-closes-others | insert of B fails | A still running |
| billing-timer-003 | start-resolves-project | request with no project, root `/app`, branch `main`, and `/app` mapped to project p1 | segment has project p1 and the matching repo id |
| billing-timer-004 | start-resolves-project | request names project p2 | project p2 is kept |
| billing-timer-005 | stop | timer started 10:00:00Z, stop at 10:30:00Z | closed, 1800 seconds |
| billing-timer-006 | stop-unknown | stop of `missing` | throws `unknownTimer` |
| billing-timer-007 | stop-not-running | stop of a closed segment | throws `notRunning` |
| billing-timer-008 | stop-all-manual-only | one manual timer and one derived run running | returns 1; the derived run is still running |
| billing-timer-009 | flag-runaways | manual timer running 9 hours, cap 8 hours | flagged `runaway`, returns 1, still running |
| billing-timer-010 | flag-runaways | manual timer running 7 hours, cap 8 hours | not flagged, returns 0 |
| billing-timer-011 | cap-non-positive | cap 0 | returns 0 |

## Edge Cases

- Stopping with a clock earlier than the start yields whatever the shared seconds function returns for that pair; no guard is added here.
- Flagging the same timer twice counts it only when the flag was newly added.
- The stop reads the segment again after closing it; if it vanished in between the call throws `unknownTimer`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| now | UTC timestamp string | current time | Injected clock for every operation. |
| capSeconds | integer | from preferences | Runaway threshold in seconds. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Timer failures are presented as the shared billing refusal sentences, which are fixed English text, not localized.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: the timer makes no log calls; failures are thrown to the caller.

## Platform Notes

- **SwiftUI**: Not used; the service has no view layer.
- **Compose**: A suspend-free service over the persistence interface; run `start` inside `withTransaction`.
- **React/Web**: A service over an async repository; do the close-then-insert in one transaction.
- **AppKit / UIKit**: A Foundation-only enum namespace; `TimeZone.current.identifier` for the zone and `UUID().uuidString` for the id.
- **WinUI 3**: A static or injected service using `Guid.NewGuid()` and `TimeZoneInfo.Local.Id` (IANA id via `TimeZoneInfo.Local.HasIanaId` or a converter); wrap close-and-insert in one `SqliteTransaction`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingTimer.swift` |

## Design Decisions

**Decision**: A runaway timer is flagged, not stopped.
**Rationale**: The daemon cannot tell a nine-hour day from a forgotten timer; stopping would invent an end and truncating would lose real hours. The question is left to the only person who knows.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: the timer owns only the manual-timer rules and delegates claim resolution to the store, storage to the persistence contract and arithmetic to the shared timestamp utility. unit-test-coverage fails: a search of the Tests directories finds no test of `BillingTimer`; the app-level `FakeBillingClient` implements the billing service rather than calling this type, so nothing in this repository exercises it; it runs only inside a host's daemon.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
