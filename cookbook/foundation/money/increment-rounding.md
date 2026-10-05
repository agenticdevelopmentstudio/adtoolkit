---
id: E846A572-E09A-4123-A6BF-4766A8460154
title: "Increment Rounding"
domain: adtoolkit://cookbook/foundation/money/increment-rounding
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Rounds a whole quantity to a whole number of increments, upward or to the nearest, in integers."
platforms:
  - swift
  - macos
tags:
  - foundation
  - money
  - billing
  - rounding
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money
references: []
approved-by: ""
approved-date: ""
---

# Increment Rounding

## Overview

Rounds a whole quantity to a whole number of increments, such as billed seconds to fifteen-minute blocks, in integers throughout. It is the other half of the arithmetic that turns seconds into money: that turns seconds into an amount, this decides which seconds count. Two modes exist: always to the next increment, where one second of a fifteen-minute block bills fifteen minutes, and to the closest increment with half rounding up, where seven minutes thirty seconds of fifteen bills fifteen minutes and seven minutes twenty-nine seconds bills none.

## Behavioral Requirements

- **modes**: The rounding MUST offer exactly two modes, upward, whose raw value is `up`, and nearest, whose raw value is `nearest`, and MUST expose both.
- **upward**: Upward MUST round a positive value to the next whole multiple of the increment; a value already a multiple MUST stay unchanged.
- **nearest-half-up**: Nearest MUST round to the closest multiple of the increment, with an exact half going up.
- **zero-increment-passes**: An increment of zero or less MUST mean no rounding: the value passes through, and MUST NOT round to zero.
- **nonpositive-value-is-zero**: A value of zero or less MUST round to zero in both modes, so nothing never acquires a minimum increment.
- **value-guard-first**: The nonpositive-value rule MUST take precedence over the zero-increment rule.
- **integer-only**: The arithmetic MUST be entirely in integers.

## Appearance

Not applicable: The rounding rule is not a visual component.

## States

Not applicable: The rounding rule is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The rounding rule presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| increment-rounding-001 | upward | Round 1 second to a 900-second increment, upward. | 900 (test: testUpwardAlwaysTakesTheNextIncrement). |
| increment-rounding-002 | upward | Round 900 to a 900 increment, upward. | 900. |
| increment-rounding-003 | nearest-half-up | Round 450 to a 900 increment, nearest. | 900: the half goes up. |
| increment-rounding-004 | nearest-half-up | Round 449 to a 900 increment, nearest. | 0 (test: testNearestRoundsHalfUp). |
| increment-rounding-005 | zero-increment-passes | Round 1234 with an increment of 0, then of -5. | 1234 each time (test: testNoIncrementMeansNoRoundingAndNothingStaysNothing). |
| increment-rounding-006 | nonpositive-value-is-zero, value-guard-first | Round 0 and -10 with increment 900, and 0 with increment 0. | 0 in every case. |
| increment-rounding-007 | modes | Read the raw values of the two modes. | `up` and `nearest`. |

## Edge Cases

- **Null / empty input**: A quantity of zero is nothing and stays nothing.
- **Boundary values**: An exact multiple is unchanged in upward mode; the exact half goes up in nearest mode; an increment of one leaves the value unchanged in both modes.
- **Concurrent access**: It is a stateless pure function.
- **Error states**: It never fails; a very large value times two could overflow the integer width, which traps in Swift, and no guard is added.
- **Offline / disconnected state**: Not applicable: The rounding rule has no network access.
- **Cancellation**: Not applicable: The rounding rule has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| mode | upward or nearest | none, required | Which rounding to apply. |
| increment | integer | none, required | The block size in the quantity's unit; zero or less means no rounding. |

The rounding rule reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The rounding rule defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The rounding rule contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The rounding rule presents no UI.

## Feature Flags

Not applicable: The rounding rule contains no feature-flag reference.

## Analytics

Not applicable: The rounding rule contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The rounding rule calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `String`-backed `enum` conforming to `Sendable` and `CaseIterable`, with a `round` method.
- **Compose**: An `enum class` with a `round(value, increment)` function using integer division; keep `Int` or `Long` arithmetic.
- **React/Web**: A string union `'up' | 'nearest'` and a pure function using `Math.trunc` division on integers.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: An `enum IncrementRounding { Upward, Nearest }` with an extension method `Round(int value, int increment)` using integer arithmetic only; avoid `Math.Round`, whose default is banker's rounding.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Money/IncrementRounding.swift` |

## Design Decisions

**Decision**: A non-positive increment disables rounding rather than rounding to zero.
**Rationale**: Rounding every value to zero because a configuration said no increment would erase the bill; passing the value through makes "no increment" safe.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type rounds quantities only; converting to money and formatting are in other specs. `unit-test-coverage` passes because `IncrementRoundingTests` in `AgenticToolkitCoreTests/MoneyTotalsTests.swift` covers upward rounding, nearest half-up, and the zero-increment and zero-value rules.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
