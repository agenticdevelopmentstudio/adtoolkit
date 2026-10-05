---
id: A98DFCA4-B6B0-4565-91B3-0657981D1AC8
title: "Local Time Text"
domain: adtoolkit://cookbook/foundation/time/local-time-text
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Times of day the way a viewer reads and types them: locale-aware clocks, month-and-day in the locale's order, and either clock accepted when typed."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - formatting
  - locale
depends-on: []
related:
  - adtoolkit://cookbook/foundation/time/utc-timestamp
  - adtoolkit://cookbook/foundation/time/timestamp-parsing
references: []
approved-by: ""
approved-date: ""
---

# Local Time Text

## Overview

Times of day the way a viewer reads and types them: a 12-hour clock where their locale uses one, a 24-hour clock where it does not, the month and day in the locale's own order, and either clock accepted when typed. Every formatter is built once per pattern, zone and locale and reused, because a table of timestamps renders hundreds of rows per refresh and a formatter costs tens of microseconds to build against well under one to reuse; the cache is lock-guarded so any thread may format. It is for display and entry only: the wire form every process compares as a string is the UTC timestamp's, never this one.

## Behavioral Requirements

- **clock-text**: The clock text for an instant MUST be `h:mm a` in a locale that uses a 12-hour clock (`2:05 PM`) and `H:mm` in one that does not (`14:05`), in the given time zone and locale.
- **day-and-clock**: The day-and-clock text MUST be the month and day in the locale's own order, a comma and space, then the clock text (`Sep 24, 2:05 PM`, `24 Sep, 14:05`).
- **twelve-hour-detection**: The locale MUST be classified as 12-hour when its localized hour template contains a day-period marker.
- **parse-locale-first**: Parsing typed text MUST try the viewer's own clock pattern first, then `h:mm a`, `h:mma`, `h a` and `ha` in a fixed POSIX locale.
- **parse-twenty-four-hour**: If no marked pattern matches, parsing MUST try `H:mm` and `H`, so `14:05` and a bare `14` are accepted whatever the locale.
- **parse-ambiguous-bare-time**: In a 12-hour locale a bare time whose hour is 1 to 12 and which carries no day-period marker MUST return both readings, the typed hour and that hour plus twelve; otherwise it MUST return one reading.
- **parse-not-a-time**: Text that matches no pattern, or that is empty after trimming whitespace, MUST return no readings.
- **parse-strict**: Formatters MUST be non-lenient, so out-of-range fields do not wrap into a valid time.
- **nearest-instant**: Resolving a typed clock against a reference instant MUST consider the reference's day and the days either side in the given zone, for every candidate clock, and MUST return the instant closest to the reference, nothing if none can be built.
- **start-of-day**: The start of a `yyyy-MM-dd` day MUST be the instant that day begins in the given zone, or nothing when the text is not a day.
- **integer-seconds-between**: The seconds between two instants MUST be whole seconds computed without a floating-point intermediate.
- **formatter-cache**: Formatters MUST be cached by pattern, zone identifier and locale identifier, and the cache MUST be guarded by a lock so any thread may format.

## Appearance

Not applicable: The text helper is not a visual component.

## States

Not applicable: The text helper is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The text helper presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| local-time-text-001 | clock-text | Format 2026-09-22T14:05:00Z in UTC for en_US and en_GB. | Text starting `2:05` (the test asserts only the prefix, since the day-period spacing is the platform's) and exactly `14:05` (test: testTheClockFollowsTheLocale). |
| local-time-text-002 | parse-locale-first, parse-twenty-four-hour | Parse `2:05 PM` and `2pm` in en_GB, and `14:05` in en_US. | Clocks of 14:05, 14:00 and 14:05 (test: testEitherClockIsAcceptedWhenTyped, which does not cover `2:05pm`, `2 PM` or a bare `14`). |
| local-time-text-003 | parse-ambiguous-bare-time | Parse `2:05` in a 12-hour locale and in a 24-hour locale. | Two readings, 02:05 and 14:05, in the 12-hour locale; one, 02:05, in the 24-hour one (test: testABareTimeIsAmbiguousOnlyOnATwelveHourClock). |
| local-time-text-004 | nearest-instant | Reference `2026-09-22T23:55:00Z` in UTC; typed clock 00:10. | `2026-09-23T00:10:00Z`, on the next day, being nearest (test: testTheNearestInstantMayFallOnTheNextDay). |
| local-time-text-005 | start-of-day, integer-seconds-between | Start of `2026-09-22` in UTC; start of `someday`; seconds between the start and one hour later. | Epoch 1,790,035,200; nothing; 3600 (test: testStartOfDayAndSeconds). |
| local-time-text-006 | parse-not-a-time | Parse `not a time` (test: testEitherClockIsAcceptedWhenTyped), and the empty string (untested). | No readings. |

## Edge Cases

- **Null / empty input**: Empty or whitespace-only text yields no readings; an empty day text yields no instant.
- **Boundary values**: The nearest-instant search spans three calendar days, so a time past midnight resolves into the next day; a clock that cannot be built on a candidate day is skipped, and a time typed inside a daylight-saving gap resolves however the platform calendar builds it.
- **Concurrent access**: The formatter map is guarded by one lock; formatters themselves are safe to use once configured.
- **Error states**: No function throws; unparseable input yields no readings or no instant.
- **Offline / disconnected state**: Not applicable: The text helper has no network access.
- **Cancellation**: Not applicable: The text helper has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The text helper reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The text helper defines no URL scheme, route or navigation destination.

## Localization

Every clock and day string is produced through the locale, so the 12 or 24-hour clock, the month-day order, the day-period markers and the month names localize with the supplied locale; the type has no string literal of its own to translate.

## Accessibility Options

Not applicable: The text helper presents no UI.

## Feature Flags

Not applicable: The text helper contains no feature-flag reference.

## Analytics

Not applicable: The text helper contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The text helper calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It uses `DateFormatter` with `dateFormat(fromTemplate:)` for the locale's month-day order and a `Cache` class marked `@unchecked Sendable` with an `NSLock`.
- **Compose**: Use `DateTimeFormatter.ofLocalizedTime` and `DateFormat.is24HourFormat`; parse with several `DateTimeFormatter` patterns in order and `ZonedDateTime` for the nearest-instant search.
- **React/Web**: `Intl.DateTimeFormat(locale, {hour: 'numeric', minute: '2-digit', timeZone})` and `resolvedOptions().hour12` for the classification; cache formatters in a `Map` keyed by `pattern|zone|locale`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use `CultureInfo.DateTimeFormat.ShortTimePattern` to classify the clock, `DateTime.TryParseExact` with an explicit pattern list for entry, and `TimeZoneInfo` for the zone; bind a `TimePicker` or `TextBox` and call the parser on commit.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Time/LocalTimeText.swift` |

## Design Decisions

**Decision**: Formatters are cached by pattern, zone and locale.
**Rationale**: A table renders hundreds of rows per refresh, and a formatter costs tens of microseconds to build against well under one to reuse; the lock covers only the map.
**Approved**: pending

**Decision**: An ambiguous bare time returns both readings and leaves the choice to the caller.
**Rationale**: In a 12-hour locale a time typed over a shown one means whichever end of the day is nearest what the cell showed, which only the caller knows.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only formats and parses times of day for people and keeps the wire form in the UTC timestamp spec. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Time/LocalTimeTextTests.swift` covers locale-following clocks, either clock accepted when typed, the ambiguous bare time, a next-day nearest instant and start-of-day with seconds arithmetic.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
