---
id: E3A194DC-3ACC-4206-AE6E-105A15FB9F55
title: "Duration Formatter"
domain: adtoolkit://cookbook/foundation/time/duration-formatter
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Integer seconds rendered as hours and minutes, decimal hours or a clock, and typed durations parsed back, with no floating-point number on the billing path."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - formatting
  - billing
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money
  - adtoolkit://cookbook/foundation/money/increment-rounding
references: []
approved-by: ""
approved-date: ""
---

# Duration Formatter

## Overview

Integer seconds rendered three ways: hours and minutes for reading, decimal hours for transcribing into a client's billing tool, and a clock for a running timer. It also parses a typed duration back into seconds. It exists because the billing path must never route a duration through a floating-point number, so every conversion is integer arithmetic with half-up rounding. It does not converge the repository's other duration formatters; that is separate work.

## Behavioral Requirements

- **hours-minutes**: The reading form MUST be `Nh Mm`, with the hour part omitted when zero (`45m`) and the minute part omitted when zero (`2h`); seconds below a minute MUST round down to `0m` rather than imply precision the rounding rules have discarded.
- **decimal-hours**: The decimal-hours form MUST be seconds divided by 3600 rounded half-up at a configurable number of places, default 2, computed entirely in integers (`8100` seconds is `2.25`).
- **decimal-places-clamped**: A negative number of places MUST be treated as zero, in which case the result has no decimal point.
- **clock-form**: The clock form MUST be `H:MM:SS`, with hours not zero-padded and not wrapped at 24, and minutes and seconds two digits.
- **negative-clamps-to-zero**: Every formatter MUST treat negative seconds as zero.
- **parse-decimal-hours**: Parsing MUST accept decimal hours with a period or a comma (`1.5`, `0.25`, `.5`, `1,5`) and a bare integer, converting the fraction to seconds by digits times 3600 divided by 10 to the power of the digit count, rounded half-up, in integers.
- **parse-clock**: Parsing MUST accept a clock `H:MM` whose minutes are exactly two digits and below 60.
- **parse-units**: Parsing MUST accept an hours part, a minutes part, or both with hours first: `1h 30m`, `1h30m`, `2h`, `90m`, with spaces ignored and the case folded; minutes before hours (`30m1h`) and a fractional unit part (`1.5h`) are refused.
- **parse-six-digit-cap**: Each digit run in a parsed duration MUST be plain ASCII digits and at most six long, so every product stays in range.
- **parse-refuses-the-rest**: Parsing MUST return nothing for negative numbers, empty text, more than one decimal separator, and anything else it does not recognize.
- **policy-is-callers**: Whether a parsed duration is allowed (not zero, not over a day) MUST be left to the caller.

## Appearance

Not applicable: The formatter is not a visual component.

## States

Not applicable: The formatter is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The formatter presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| duration-formatter-001 | hours-minutes | Format 8,100 seconds, 7,200 seconds, 2,700 seconds and 59 seconds. | `2h 15m`, `2h`, `45m`, `0m` (test: testHoursMinutes). |
| duration-formatter-002 | decimal-hours | Decimal hours for 8,100 seconds, and for 1,800 seconds. | `2.25` and `0.50` (test: testDecimalHours). |
| duration-formatter-003 | decimal-hours | Decimal hours for 1 second at 2 places. | `0.00`; for 10 seconds, `0.00`; for 18 seconds, `0.01` (test: testDecimalHoursRoundsHalfUp). |
| duration-formatter-004 | clock-form | Clock form for 8,100 and 90,000 seconds. | `2:15:00` and `25:00:00` (test: testClock). |
| duration-formatter-005 | negative-clamps-to-zero | Format -30 seconds in each form. | `0m`, `0.00`, `0:00:00` (test: testNegativeSecondsClampToZero). |
| duration-formatter-006 | parse-decimal-hours, parse-clock, parse-units | Parse `1.5`, `1:30`, `1h 30m`, `90m`, `.5`, `1,5`. | 5,400, 5,400, 5,400, 5,400, 1,800, 5,400 (test: testSecondsParsingAcceptsTheCommonForms). |
| duration-formatter-007 | parse-refuses-the-rest | Parse `-1`, `1:5`, `abc`, `1.2.3` and the empty string. | Nothing for each (test: testSecondsParsingRefusesWhatIsNotADuration). |

## Edge Cases

- **Null / empty input**: Empty or whitespace-only text parses to nothing; zero seconds formats as `0m`, `0.00` and `0:00:00`.
- **Boundary values**: Hours are never wrapped, so 90,000 seconds is `25h` and `25:00:00`; a digit run of seven digits is refused; a clock with minutes of 60 or one-digit minutes is refused.
- **Concurrent access**: Stateless pure functions.
- **Error states**: Parsing returns nothing; formatting cannot fail. Very large second counts could overflow the integer width in the decimal-hours multiplication, which traps in Swift; the type adds no guard.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| places | non-negative integer | 2 | Decimal places for the decimal-hours form. |

The formatter reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The formatter defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The formatter contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The formatter presents no UI.

## Feature Flags

Not applicable: The formatter contains no feature-flag reference.

## Analytics

Not applicable: The formatter contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The formatter calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; `String(format:)` pads the minutes, seconds and decimal fraction.
- **Compose**: Top-level functions using integer arithmetic and `String.format("%d:%02d:%02d")`; the localized duration APIs (`DateUtils.formatElapsedTime`) do not give the decimal-hours form.
- **React/Web**: Pure functions using integer `Math.floor` and string padding; never divide seconds by 3600 as a float for the decimal form.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers using `int` arithmetic and `ToString("D2")`; a `TextBox` bound to a duration can call the parser on `LostFocus` and keep the old value when it returns null.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Time/DurationFormatter.swift` |

## Design Decisions

**Decision**: No floating-point number is used anywhere in the formatter or the parser.
**Rationale**: The billing path must stay exact: a Double would let a rounding error change an invoice, so fractions of an hour become seconds by integer arithmetic with half-up rounding.
**Approved**: pending

**Decision**: Seconds below a minute round down to `0m` in the reading form.
**Rationale**: The rounding rules already discarded sub-minute precision, and showing seconds would imply precision the billed figure does not have.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only converts between integer seconds and text; whether a duration is allowed is the caller's decision. `unit-test-coverage` passes because `AgenticToolkitCoreTests/DurationFormatterTests.swift` covers the reading form, decimal hours and half-up rounding, the clock, negative clamping, and parsing of the common forms, half-up fractions and refused input.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
