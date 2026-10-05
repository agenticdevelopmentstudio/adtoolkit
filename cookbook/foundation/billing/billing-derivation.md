---
id: BC417768-9933-49B1-B0BA-4BF537167805
title: "Billing Derivation"
domain: adtoolkit://cookbook/foundation/billing/billing-derivation
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A pure function that turns a session's activity timestamps into closed or open runs of work."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - derivation
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-activity-cache
  - adtoolkit://cookbook/foundation/billing/billing-rollup
  - adtoolkit://cookbook/foundation/billing/billing-store
references: []
approved-by: ""
approved-date: ""
---

# Billing Derivation

## Overview

Turns a session's activity timestamps into runs: continuous stretches of work split wherever the idle gap exceeds a cutoff. The derivation is pure and re-derivable from the same events, so a crash, a reinstall mid-session, a laptop sleep or a timer nobody stopped cost nothing: sleep produces a gap, a gap produces a split. The price is up to one scheduling interval of lag, and a run still open is not yet billable. A run closes at the previous event, so the idle stretch that revealed the stop is never billed. Two entry points exist: one over raw timestamp strings, one over already parsed, sorted, unique epoch seconds (the form the activity cache keeps).

## Behavioral Requirements

- **run-shape**: A run MUST carry `startedAt`, `endedAt` and `seconds`; an empty `endedAt` marks an open run, whose `seconds` MUST be 0.
- **parse-sort-dedupe**: The string entry point MUST drop unparseable timestamps, de-duplicate by whole epoch second, and sort ascending before splitting, so out-of-order arrival never yields a negative-length run.
- **split-on-gap**: Activity MUST split into runs at every gap strictly greater than the cutoff; a gap exactly equal to the cutoff MUST NOT split. A run closes at the last event before the gap.
- **no-activity-no-runs**: With no activity the result MUST be empty.
- **single-event**: A single event MUST yield exactly one run that starts and ends at that event; it is a closed run of zero seconds unless the open-final-run rule keeps it open.
- **cutoff-default**: A cutoff of zero or less MUST be replaced by the default of 15 minutes (900 seconds).
- **first-run-lead-in**: The first run MUST start at the session start instead of its first event when the session start parses, precedes the first event, and is within the cutoff of it. Later runs MUST get no lead-in.
- **open-final-run**: The final run MUST stay open only when the session is active and `now` parses and is within the cutoff of the last event; otherwise it MUST close at the last event.
- **malformed-now-closes**: A malformed `now` MUST close the final run rather than leave it open.
- **seconds-non-negative**: A closed run's `seconds` MUST be the end minus the start, never negative.
- **caller-supplies-clock**: The derivation MUST NOT read the current time; the caller passes `now`.
- **deterministic**: The same inputs MUST produce the same runs.

## Appearance

Not applicable — this is a pure derivation function, not a visual component.

## States

Not applicable — this is a pure derivation function, not a visual component.

## Accessibility

Not applicable — this is a pure derivation function, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-derivation-001 | no-activity-no-runs | no timestamps | empty |
| billing-derivation-002 | single-event | one event at minute 0; session not active | one run, start = end = minute 0, 0 seconds |
| billing-derivation-003 | split-on-gap | events at minutes 0, 5, 10, 14, 20; cutoff 15 | one run, 0 to 20, 1200 seconds |
| billing-derivation-004 | split-on-gap | events at 0, 10, 40, 45 | two runs; the first ends at minute 10 (600 seconds) |
| billing-derivation-005 | split-on-gap | events at 0 and 15 (gap equals cutoff) | one run |
| billing-derivation-006 | open-final-run | events at 0, 10; active; now minute 15 | one open run, empty `endedAt`, 0 seconds |
| billing-derivation-007 | open-final-run | events at 0, 10; active; now minute 40 | run closed at minute 10 |
| billing-derivation-008 | open-final-run | events at 0, 10; not active; now minute 12 | run closed at minute 10 |
| billing-derivation-009 | first-run-lead-in | events at 10, 15; session start minute 0 | first run starts at minute 0, 900 seconds |
| billing-derivation-010 | first-run-lead-in | events at 40, 45; session start minute 0 | first run starts at minute 40 |
| billing-derivation-011 | first-run-lead-in | events at 10, 15, 60, 65; session start minute 0 | second run starts at minute 60 |
| billing-derivation-012 | first-run-lead-in | events at 0, 5; session start minute 3 | first run starts at minute 0 |
| billing-derivation-013 | parse-sort-dedupe | events at 20, 0, 10 | one run, 0 to 20 |
| billing-derivation-014 | malformed-now-closes | events at 0, 10; active; now `garbage` | run closed at minute 10 |
| billing-derivation-015 | cutoff-default | cutoff 0 with a 14-minute gap | one run (default cutoff applies) |

## Edge Cases

- Unparseable timestamps are dropped silently; if all are dropped the result is empty.
- Fractional-second stamps count as activity at their whole second; mixed stamp forms sort by instant.
- The session start may be in the space-separated form the store writes.
- A malformed session start is ignored (no lead-in).
- Time before a later run's first event is lost, not invented.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| cutoffSeconds | integer | 900 when not positive | Idle gap that ends a run. |
| now | UTC timestamp string | caller supplied | Clock used to decide whether the last run is still open. |

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

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the function has no view layer.
- **Compose**: A pure function over `List<Long>`; reuse a shared activity-run splitter.
- **React/Web**: A pure function over `number[]`; use `Date.parse` or Temporal for timestamps.
- **AppKit / UIKit**: Foundation-only; splitting is delegated to the shared `ActivityRuns.split` and timestamp handling to `UTCTimestamp`.
- **WinUI 3**: A static method over `long` seconds; `DateTimeOffset.TryParse` for inputs; `IReadOnlyList<BillingRun>` result.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingDerivation.swift` |

## Design Decisions

**Decision**: Time before the first event of a later run is not billed.
**Rationale**: Only the session start is evidence for the first run's lead-in; later runs have no defensible source, so their head time is lost rather than invented.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: derivation is pure; clocks, parsing and splitting are shared utilities and the caller supplies `now`. unit-test-coverage passes: `BillingDerivationTests` covers splitting, the cutoff boundary, sleep, open and closed final runs, lead-in, out-of-order, unparseable and malformed inputs, and fractional stamps.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
