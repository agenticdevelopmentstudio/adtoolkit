---
id: 7233995D-9B7E-4760-AC44-AB4B668B5CC1
title: "Money"
domain: adtoolkit://cookbook/foundation/money
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An amount of money as integer hundredths of a major unit with an ISO-4217 currency code, with exact arithmetic that refuses mixed currencies."
platforms:
  - swift
  - macos
tags:
  - foundation
  - money
  - currency
  - arithmetic
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money/money-formatter
  - adtoolkit://cookbook/foundation/money/money-totals
  - adtoolkit://cookbook/foundation/money/currency-code
  - adtoolkit://cookbook/foundation/money/increment-rounding
references: []
approved-by: ""
approved-date: ""
---

# Money

## Overview

An amount of money held as an integer count of hundredths of the currency's major unit, plus an ISO-4217 currency code, with no floating-point number anywhere. A rate of $0.10 per hour applied to three minutes is exactly half a cent, and a binary float cannot hold the tenths it takes to get there. The unit is always hundredths whatever the currency's own minor unit is, so every currency shares one scale with the formatter. It is for code that wants the currency carried alongside the amount and mixed currencies refused; callers that already hold a bare integer can use the seconds-times-rate helper and the formatter without constructing one. Addition, subtraction, comparison and summing refuse to mix currencies, and no conversion exists anywhere.

## Behavioral Requirements

- **integer-hundredths**: The amount MUST be an integer count of hundredths of the currency's major unit, never a fraction, and the type MUST NOT use a floating-point number.
- **currency-default-usd**: The currency MUST default to `USD` when the caller omits it.
- **currency-carried-no-conversion**: The currency code MUST be carried so a total can refuse to mix currencies; no conversion between currencies MUST be performed anywhere.
- **same-currency-test**: The type MUST report whether two amounts share a currency, by exact code equality.
- **mixed-currency-is-programmer-error**: Comparing, adding or subtracting amounts of different currencies MUST fail as a programmer error, never return a result or a false.
- **add-subtract**: Adding or subtracting same-currency amounts MUST return an amount in that currency whose hundredths are the sum or difference.
- **ordering**: Same-currency amounts MUST be ordered by their hundredths.
- **sum-of-list**: Summing a list MUST add through the addition rule, so a mixed list fails; an empty list MUST sum to zero in the given currency (default `USD`) rather than nothing.
- **amount-from-seconds**: The amount for a number of seconds at an hourly rate in hundredths MUST be seconds times rate divided by 3600, rounded half-up, entirely in integers.
- **amount-zero-guards**: The seconds-to-amount function MUST return zero when the seconds are zero or negative or when the rate is zero.
- **amount-sign-preserved**: A negative rate MUST produce a negative amount whose magnitude is rounded half-up, so rounding is symmetric about zero.
- **codable-equatable**: The amount MUST be encodable, decodable and equal exactly when hundredths and currency are both equal.

## Appearance

Not applicable: The money type is not a visual component.

## States

Not applicable: The money type is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The money type presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-001 | amount-from-seconds | 3600 seconds at a rate of 12,500. | 12,500 (test: testAmountCentsIsExactForWholeHours). |
| money-002 | amount-from-seconds | 900 seconds at a rate of 12,500. | 3,125 (test: testAmountCentsForAQuarterHour). |
| money-003 | amount-from-seconds | 1800 seconds at a rate of 1, then 1799 seconds at a rate of 1. | 1, then 0: half-up at the boundary (test: testAmountCentsRoundsHalfUp). |
| money-004 | amount-sign-preserved | 3600 seconds at a rate of -12,500; 1800 seconds at a rate of -1. | -12,500 and -1 (test: testAmountCentsPreservesNegativeRateSign). |
| money-005 | amount-zero-guards | 0 seconds, then -60 seconds, at 12,500; and 86,400 seconds at rate 0. | Each returns 0. |
| money-006 | sum-of-list | Sum an empty list in `EUR`. | Zero hundredths in `EUR` (test: testSumOfNothingIsZero). |
| money-007 | add-subtract, ordering | 100 minus 300 in `USD`; 99 compared with 100. | -200; 99 is less than 100. |
| money-008 | same-currency-test | Compare `USD` with `USD` and `USD` with `EUR`. | True, then false (test: testMixedCurrenciesAreNotTheSameCurrency). |
| money-009 | mixed-currency-is-programmer-error | Add 1 `USD` to 1 `EUR`. | Fails as a programmer error. |

## Edge Cases

- **Null / empty input**: An empty list sums to zero in the requested currency (`sum-of-list`); an empty currency string is accepted by the type, because only the three-letter shape rule in the currency-code spec validates codes.
- **Boundary values**: Seconds times rate is computed in the platform integer width, so a product that exceeds it overflows, which traps in Swift; the type adds no guard. Zero hundredths is a valid amount.
- **Concurrent access**: The type is an immutable value and is safe to share across threads.
- **Error states**: Mixed-currency arithmetic and comparison fail as programmer errors rather than returning an error value.
- **Offline / disconnected state**: Not applicable: The money type has no network access.
- **Cancellation**: Not applicable: The money type has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The money type reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The money type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The money type contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The money type presents no UI.

## Feature Flags

Not applicable: The money type contains no feature-flag reference.

## Analytics

Not applicable: The money type contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The money type calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `struct` conforming to `Codable`, `Sendable`, `Equatable` and `Comparable`, and mixed-currency operators use `precondition`.
- **Compose**: A `data class Money(val cents: Long, val currency: String = "USD")` with `operator` functions that `require` same currency; use `Long` to avoid overflow, and `BigDecimal` only at the formatting edge.
- **React/Web**: A class over `bigint` or a safe integer with `add`, `subtract` and `compare` that throw on mixed currencies; never use `number` fractions for the stored amount.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `readonly record struct Money(long Cents, string Currency = "USD")` with `operator +`, `-` and `IComparable<Money>` that throw `InvalidOperationException` on mixed currencies; use `long` hundredths and `decimal` only for display.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Money/Money.swift` |

## Design Decisions

**Decision**: Mixed-currency arithmetic fails rather than returning an error or a relabeled amount.
**Rationale**: Adding across currencies would silently relabel one amount as the other's currency, and ordering them is meaningless, so the type treats it as a programmer error caught in development rather than a value a caller must check.
**Approved**: pending

**Decision**: Seconds-to-amount rounds half-up, not banker's.
**Rationale**: Half-up is what a person checking the arithmetic by hand expects, and these amounts are not numerous enough for the statistical bias banker's rounding exists to remove to arise.
**Approved**: pending

**Decision**: The scale is always hundredths, whatever the currency's own minor unit.
**Rationale**: A shared scale means parsing multiplies by 100 and display divides by 100 for every currency, so the formatter and the type agree for currencies with no minor unit or three.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |

`separation-of-concerns` passes because the type only represents and combines amounts; formatting, parsing, rounding to increments and per-currency bucketing live in the sibling money specs. `unit-test-coverage` passes because `AgenticToolkitCoreTests/MoneyTests.swift` covers the seconds-to-amount arithmetic including rounding, sign and zero guards, summing, subtraction, ordering and the same-currency test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
