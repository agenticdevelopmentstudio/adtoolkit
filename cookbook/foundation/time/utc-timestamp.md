---
id: 59F7893E-58FE-4F11-ABD9-F80C1E05C002
title: "UTC Timestamp"
domain: adtoolkit://cookbook/foundation/time/utc-timestamp
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The fixed-width UTC wire instant `yyyy-MM-ddTHH:mm:ssZ` and the `yyyy-MM-dd` day keys derived from it, written and read without a formatter."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - timestamps
  - wire-format
depends-on: []
related:
  - adtoolkit://cookbook/foundation/time/timestamp-parsing
  - adtoolkit://cookbook/foundation/time/local-time-text
  - adtoolkit://cookbook/foundation/time/activity-runs
references: []
approved-by: ""
approved-date: ""
---

# UTC Timestamp

## Overview

The wire instant (`yyyy-MM-dd'T'HH:mm:ss'Z'`, whole seconds, UTC) and the `yyyy-MM-dd` day keys derived from it, written and read without a formatter. It is one owner for a cross-process format: a daemon that compares instants as fixed-width strings (sorting, run bounds, interval walks) is only chronological while every writer produces the same width, so every writer goes through here. Parsing tries a hand-written fixed-width fast path first, because a formatter costs tens of microseconds to build and a daemon parsing every activity stamp of a long session spent most of its CPU building them, and falls back to the shared timestamp parser for every other shape, so what is accepted is exactly what the shared parser accepts plus SQLite's millisecond form.

## Behavioral Requirements

- **wire-form**: A written instant MUST be `yyyy-MM-ddTHH:mm:ssZ`: four-digit year, two-digit month, day, hour, minute and second, in UTC, whole seconds, no fraction, so equal-width strings sort chronologically.
- **fractions-truncate**: Writing from an instant with a fractional second MUST truncate toward the earlier second, so an instant never reads later than it happened; negative epoch values MUST floor.
- **now**: The type MUST offer the current instant as a wire string.
- **days-ago**: The wire instant `days` whole days before a reference (default now) MUST be the lower bound a recent query sends.
- **day-key**: The day key for an instant in a time zone MUST be the `yyyy-MM-dd` calendar day the instant falls on in that zone, adding the zone's offset at that instant before taking the date.
- **read-epoch-seconds**: Reading MUST return whole seconds since 1970 for any accepted shape, truncating any fraction, or nothing when the text does not parse.
- **read-date**: Reading to a date MUST include the fraction, or nothing when the text does not parse.
- **fast-path-shapes**: The fast path MUST accept `yyyy-MM-ddTHH:mm:ss[.fraction]Z` with a fraction of any width, and `yyyy-MM-dd HH:mm:ss[.SSS]` with either no fraction or exactly three digits and no zone (SQLite, UTC).
- **fast-path-validates**: The fast path MUST return nothing, so the caller falls back, for offsets, odd widths and out-of-range fields: month outside 1 to 12, day beyond the month's length including leap years, hour 24 or more, minute or second 60 or more.
- **fallback-to-shared-parser**: When the fast path declines, reading MUST fall back to the shared timestamp parser.
- **canonical**: The canonical form of any accepted shape MUST be the wire form of its whole seconds, or nothing if it does not parse, so stored instants compare as strings.
- **seconds-between**: The seconds from a start to an end text MUST be zero when either is unparseable or the end is before the start; a negative duration MUST NOT silently subtract from a total.
- **adding**: Adding a whole-second delta to a text MUST return the wire form of the moved instant, or nothing when the text does not parse.
- **civil-calendar**: Date arithmetic MUST use a proleptic Gregorian days-from-civil algorithm, not a platform calendar.

## Appearance

Not applicable: The wire instant type is not a visual component.

## States

Not applicable: The wire instant type is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The wire instant type presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utc-timestamp-001 | wire-form | Write epoch seconds 0, 1,790,067,600 and -1. | `1970-01-01T00:00:00Z`, `2026-09-22T09:00:00Z` and `1969-12-31T23:59:59Z` (test: testWritesTheFixedWidthWireInstant). |
| utc-timestamp-002 | fractions-truncate | Write an instant at 1,790,067,600.999 seconds. | `2026-09-22T09:00:00Z` (test: testFractionsTruncate). |
| utc-timestamp-003 | days-ago | 14 days before a reference of `2026-09-22T09:00:00Z` (epoch 1,790,067,600). | `2026-09-08T09:00:00Z` (test: testDaysAgoIsWholeDaysBeforeTheReference). |
| utc-timestamp-004 | day-key | The day of `2026-09-23T04:30:00Z` (epoch 1,790,137,800) in America/Los_Angeles and in Europe/Berlin. | `2026-09-22` and `2026-09-23` (test: testTheDayIsTheLocalCalendarDay). |
| utc-timestamp-005 | fast-path-shapes, read-epoch-seconds | Read `2026-09-22T09:00:00.750Z`, `2026-09-22 09:00:00` and `2026-09-22T11:00:00+02:00`. | Epoch 1,790,067,600 for each; the offset form falls back to the shared parser (test: testReadsEveryStoredShape, which does not cover the SQLite millisecond form `2026-09-22 10:00:00.123`, read as epoch 1,790,071,200). |
| utc-timestamp-006 | fast-path-validates | Fast-path read of `2026-09-22T11:00:00+02:00` and `2026-13-22T09:00:00Z`. | The fast path declines each; the shared parser then decides (test: testTheFastPathRefusesWhatItCannotReadExactly, which does not exercise day-beyond-month or hour 24). |
| utc-timestamp-007 | canonical | Canonical of `2026-09-22T14:00:05.999Z` and `2026-09-22 14:00:05.123`. | `2026-09-22T14:00:05Z` for both, so neither sorts differently from the plain form of the same second (test: testCanonicalMakesInstantsComparableAsStrings). |
| utc-timestamp-008 | seconds-between | Seconds from `2026-09-22T14:00:00Z` to `2026-09-22T16:15:00Z`, the reverse pair, and from `nonsense`. | 8100, then 0 and 0 (test: testSecondsNeverGoNegative). |
| utc-timestamp-009 | adding | Add 1 to `2026-09-22T23:59:59Z`, and to `nonsense`. | `2026-09-23T00:00:00Z` and nothing (test: testAddingMovesByWholeSeconds). |

## Edge Cases

- **Null / empty input**: Empty text reads as nothing in every reader, and a duration involving it is zero.
- **Boundary values**: Leap days are accepted only in leap years (divisible by 4 and not 100, or by 400). Years are written with four digits; epoch values before year 0 or after year 9999 are not supported. The fast path needs at least 19 bytes.
- **Concurrent access**: All functions are stateless and pure apart from the clock read in now.
- **Error states**: Unparseable input returns nothing or zero seconds; nothing throws.
- **Offline / disconnected state**: Not applicable: The wire instant type has no network access.
- **Cancellation**: Not applicable: The wire instant type has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The wire instant type reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The wire instant type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The wire instant type contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The wire instant type presents no UI.

## Feature Flags

Not applicable: The wire instant type contains no feature-flag reference.

## Analytics

Not applicable: The wire instant type contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The wire instant type calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with private helpers for Hinnant's civil-date algorithms and `String(format:)` for the fixed-width output.
- **Compose**: `java.time.Instant` with `DateTimeFormatter.ISO_INSTANT` truncated to seconds covers writing; the civil-day algorithms are unnecessary on the JVM, but the validation rules and the SQLite millisecond form still need a pure parser.
- **React/Web**: `new Date(s * 1000).toISOString().slice(0, 19) + 'Z'` writes the wire form; a regex-free fixed-width reader over character codes is the fast path, falling back to `Date.parse`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: `DateTimeOffset.ToUnixTimeSeconds` and `FromUnixTimeSeconds` write and read whole seconds; `ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture)` writes the form, and `TimeZoneInfo.GetUtcOffset` supplies the offset for day keys.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Time/UTCTimestamp.swift` |

## Design Decisions

**Decision**: Reading tries a hand-written fixed-width parser before the shared formatter-based parser.
**Rationale**: A formatter costs tens of microseconds to build and a daemon parsing every stamp of a long session spent most of its CPU doing so; the fast path handles nearly every stored instant and declines anything it cannot read exactly.
**Approved**: pending

**Decision**: A backwards or unparseable pair measures zero seconds.
**Rationale**: A negative duration would silently subtract from a total, so the safe failure is no time rather than negative time.
**Approved**: pending

**Decision**: Fractions truncate rather than round.
**Rationale**: An instant must never read later than it happened, and truncation keeps equal-second stamps equal.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type owns the wire format and day keys while delegating other shapes to the shared timestamp parser and keeping locale display in the local-time spec. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Time/UTCTimestampTests.swift` covers writing, fraction truncation, days-ago, day keys, every stored shape, fast-path refusal, canonicalization, non-negative seconds, adding and date round-trips.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
