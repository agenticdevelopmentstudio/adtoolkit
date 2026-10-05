---
id: E06B149B-D083-4812-8511-AAB2998C6969
title: "Activity Runs"
domain: adtoolkit://cookbook/foundation/time/activity-runs
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The two interval algorithms behind every how-long-was-someone-working measure: splitting stamps into runs at idle gaps, and taking the union of overlapping intervals."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - intervals
  - activity
depends-on: []
related:
  - adtoolkit://cookbook/foundation/time/utc-timestamp
references: []
approved-by: ""
approved-date: ""
---

# Activity Runs

## Overview

The two interval algorithms every how-long-was-someone-working measure is built from: splitting activity stamps into runs at idle gaps, and taking the union of overlapping intervals. Both are generic over the stamp type, so epoch seconds (integer or floating point) and fixed-width ISO strings (for the union, which needs only ordering) share one copy. Policy stays with the caller: a lead-in before the first stamp, whether the last run is still open, and what the cutoff is.

## Behavioral Requirements

- **span**: A span MUST hold a start stamp and an end stamp, compared by value equality, from the first stamp of a run to the last.
- **split-at-idle-gap**: Splitting MUST take ascending stamps and an idle gap and close the running span whenever the gap to the next stamp is strictly greater than the idle gap; the closed span MUST end at the previous stamp, never extending into the idle stretch.
- **equal-gap-does-not-split**: A gap exactly equal to the idle gap MUST NOT split; the stamp joins the running span.
- **single-stamp-span**: A stamp after a split, or the first stamp, MUST open a span whose start and end are both that stamp.
- **no-stamps-no-spans**: An empty sequence of stamps MUST produce no spans.
- **streaming-splitter**: A streaming splitter MUST accept stamps one at a time in ascending order, expose the spans closed so far, and apply the same split rule as the one-shot split.
- **close-run**: The streaming splitter MUST offer closing the running span at a boundary the stamps do not show, such as the next stamp belonging to a different session; closing with no running span MUST do nothing.
- **finish**: Finishing MUST close the running span and return every span.
- **union**: The union MUST sort intervals by start and merge any intervals that overlap or touch (next start less than or equal to the current end), extending the merged end to the larger end.
- **union-ordering-only**: The union MUST need only ordering of stamps, so it MUST work for fixed-width ISO strings as well as numbers.
- **union-length**: The union length MUST be the sum of the merged spans' lengths, counting overlaps once, as wall-clock time.
- **sendable-when-stamp-is**: Spans MUST be safe to share across threads whenever their stamp type is.

## Appearance

Not applicable: The algorithms is not a visual component.

## States

Not applicable: The algorithms is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The algorithms presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-runs-001 | split-at-idle-gap | Stamps 0, 60, 120, 1000, 1030 with idle gap 300. | Two spans: 0 to 120 and 1000 to 1030 (test: testSplitsAtEveryGapLongerThanTheIdleGap). |
| activity-runs-002 | equal-gap-does-not-split | Stamps 0 and 300 with idle gap 300. | One span from 0 to 300 (test: testAGapEqualToTheIdleGapDoesNotSplit). |
| activity-runs-003 | no-stamps-no-spans | No stamps. | No spans (test: testNoStampsIsNoSpans). |
| activity-runs-004 | close-run, streaming-splitter | Add 0 and 60, close the run, add 70. | Two spans: 0 to 60 and 70 to 70 (test: testTheSplitterClosesARunAtABoundaryTheStampsDontShow). |
| activity-runs-005 | union | Intervals 0 to 10, 5 to 15 and 15 to 20. | One span 0 to 20: overlapping and touching intervals merge (test: testUnionMergesOverlappingAndTouchingIntervals). |
| activity-runs-006 | union-length | Intervals 0 to 10 and 5 to 15. | Length 15, not 20 (test: testUnionLengthCountsOverlapOnce). |
| activity-runs-007 | union-ordering-only | Intervals of ISO strings `2026-01-01T10:00:00Z` to `2026-01-01T10:30:00Z` and `...10:20:00Z` to `...10:45:00Z`. | One span from `10:00:00Z` to `10:45:00Z` (test: testUnionWorksOnFixedWidthStrings). |

## Edge Cases

- **Null / empty input**: An empty stamp sequence yields no spans; an empty interval list yields an empty union and a zero length.
- **Boundary values**: A gap equal to the idle gap joins; one unit more splits. Touching intervals merge. A single stamp yields a zero-length span.
- **Concurrent access**: The splitter is a mutable value type with no lock; each owner uses its own. The static functions are pure.
- **Error states**: No operation fails. Out-of-order stamps are outside the contract: the split would compute a negative gap and keep joining the run.
- **Offline / disconnected state**: Not applicable: The algorithms has no network access.
- **Cancellation**: Not applicable: The algorithms has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| idleGap | stamp difference | none, required | The gap beyond which two stamps are not the same run. |

The algorithms reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The algorithms defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The algorithms contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The algorithms presents no UI.

## Feature Flags

Not applicable: The algorithms contains no feature-flag reference.

## Analytics

Not applicable: The algorithms contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The algorithms calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. The algorithms are generic over `Comparable` and `AdditiveArithmetic` stamps inside a caseless `enum`, with a conditional `Sendable` conformance.
- **Compose**: Use generics `T : Comparable` with a `minus` function parameter where Kotlin's lack of `AdditiveArithmetic` requires one; `data class Span<T>` and a `Splitter` class.
- **React/Web**: Write the algorithms over `number` stamps; the union can be generic with a comparator function so ISO strings sort lexically.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A generic `Span<T> where T : IComparable<T>` record and a `Splitter<T>` that takes a `Func<T, T, T>` subtraction; for `DateTimeOffset` stamps use `TimeSpan` gaps.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Time/ActivityRuns.swift` |

## Design Decisions

**Decision**: Idle time is never part of a span.
**Rationale**: A span closes at the previous stamp because the idle stretch is how the stop is detected; counting it would overstate worked time by up to one idle gap per run.
**Approved**: pending

**Decision**: Lead-in, open-run handling and the cutoff stay with the caller.
**Rationale**: Billing, a monitor and a report each choose different policy; keeping the algorithms policy-free lets one copy serve them all.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type holds only the split and union algorithms and leaves every policy to callers. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Time/ActivityRunsTests.swift` covers gaps longer than and equal to the idle gap, no stamps, the streaming splitter's close, union merging, union length and union over strings.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
