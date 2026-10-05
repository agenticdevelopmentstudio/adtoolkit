---
id: 51BF262A-9C94-4533-A34D-1AEADF63037B
title: "Billing Clock"
domain: adtoolkit://cookbook/foundation/billing/billing-clock
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Local-day bucketing for billing: the calendar day an instant falls on in a stored zone, with a UTC fallback."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - time
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-rounding
references: []
approved-by: ""
approved-date: ""
---

# Billing Clock

## Overview

A stateless function that answers which calendar day a UTC instant belongs to in a given IANA time zone. Billing buckets work by the local day in the zone the work happened in, which is stored per segment, not by the UTC day and not by the reader's zone. Every other instant operation (parsing, formatting, canonicalising, arithmetic) belongs to the shared UTC timestamp utility; this holds only the one rule that is billing's own.

## Behavioral Requirements

- **local-day-in-zone**: Given a UTC instant string and a zone identifier, the clock MUST return the calendar day (`YYYY-MM-DD`) that instant falls on in that zone.
- **unparseable-instant-empty**: If the instant cannot be parsed by the shared UTC timestamp utility, the clock MUST return the empty string.
- **zone-fallback-utc**: An empty or unrecognised zone identifier MUST resolve to UTC, never to the host's current zone, so the same stored row buckets identically wherever it is read.
- **pure**: The clock MUST be a pure function of its two inputs: it holds no state, performs no I/O and does not read the current time.

## Appearance

Not applicable — this is a pure date function, not a visual component.

## States

Not applicable — this is a pure date function, not a visual component.

## Accessibility

Not applicable — this is a pure date function, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-clock-001 | local-day-in-zone | `2026-09-23T04:30:00Z`, `America/Los_Angeles` | `2026-09-22` |
| billing-clock-002 | local-day-in-zone | `2026-09-23T04:30:00Z`, `Europe/Berlin` | `2026-09-23` |
| billing-clock-003 | zone-fallback-utc | `2026-09-23T04:30:00Z`, empty zone | `2026-09-23` |
| billing-clock-004 | zone-fallback-utc | `2026-09-23T04:30:00Z`, `Mars/Olympus` | `2026-09-23` |
| billing-clock-005 | unparseable-instant-empty | `not-a-date`, `UTC` | empty string |

## Edge Cases

- An unparseable instant yields an empty day, not an error; callers that group by day must tolerate an empty key.
- A zone identifier that is valid but differs in case from the IANA name is treated as unrecognised if the platform rejects it, and so buckets as UTC.
- An instant exactly at local midnight belongs to the new day.

## Configuration

None: a pure date function takes no configuration beyond the values passed to each call.

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

- **SwiftUI**: Not used; the clock has no view layer.
- **Compose**: `java.time.ZonedDateTime` / `ZoneId.of`, falling back to `ZoneOffset.UTC` on `DateTimeException`.
- **React/Web**: `Intl.DateTimeFormat` with `timeZone` and `en-CA` for `YYYY-MM-DD`, or Temporal `ZonedDateTime`; catch the `RangeError` for an unknown zone and use `UTC`.
- **AppKit / UIKit**: Foundation `TimeZone(identifier:)` with a `TimeZone(identifier: "UTC")` fallback; the day string comes from the shared `UTCTimestamp.day(of:in:)`.
- **WinUI 3**: `TimeZoneInfo.FindSystemTimeZoneById` (IANA ids resolve on Windows through ICU in .NET 6+), falling back to `TimeZoneInfo.Utc` when it throws `TimeZoneNotFoundException`; format with `ToString("yyyy-MM-dd")`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingClock.swift` |

## Design Decisions

**Decision**: An unknown zone buckets as UTC instead of failing.
**Rationale**: Failing would drop the row from the rollup, and falling back to the host zone would make the answer depend on the reader; UTC is stable. Surfacing an unknown zone as an error would need a result type at every call site.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: the type owns only the billing day rule and delegates parsing and day formatting to the shared UTC timestamp utility. unit-test-coverage passes: `BillingRoundingTests` (`testLocalDayUsesTheSegmentsOwnZone`, `testLocalDayFallsBackToUTCForAnUnknownZone`) asserts the zone and fallback behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
