---
id: 9D3A57D7-C9BB-4AFC-BDAB-4C42278FD8C8
title: "Money Totals"
domain: adtoolkit://cookbook/foundation/money/money-totals
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A running total kept per currency: hundredths in each ISO-4217 code, never converted and never mixed."
platforms:
  - swift
  - macos
tags:
  - foundation
  - money
  - totals
  - currency
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money
  - adtoolkit://cookbook/foundation/money/money-formatter
references: []
approved-by: ""
approved-date: ""
---

# Money Totals

## Overview

A running total kept per currency: hundredths in each ISO-4217 code, never converted, never mixed. The money type's sum refuses mixed currencies and the formatter formats one currency, so anything that totals amounts across clients billed in different currencies needs this bucket. The wording of the result is each currency formatted on its own, in code order, joined with a plus sign, such as `€40.00 + $250.00` (`EUR` sorts before `USD`).

## Behavioral Requirements

- **buckets-per-currency**: The total MUST hold one integer hundredths figure per currency code, and only codes that were added MUST appear.
- **add-amount**: Adding hundredths in a currency, or a money value, MUST add to that currency's bucket, creating it at zero first when absent.
- **add-sequence**: Constructing from a sequence of amounts MUST add each amount into its own currency's bucket.
- **add-totals**: Adding another totals value MUST add every one of its buckets into this one's.
- **never-mixed**: Amounts in different currencies MUST never be combined into one bucket and MUST never be converted.
- **is-empty**: The total MUST report whether nothing has been added.
- **sorted-currencies**: The held currencies MUST be reported in ascending code order, and the amounts MUST be the per-currency money values in that same order.
- **description-wording**: The description MUST format each currency's total with the money formatter for that currency, in code order, joined with ` + `, and MUST be the empty string when nothing was added.
- **value-equality**: Two totals MUST be equal exactly when their buckets are equal.

## Appearance

Not applicable: The totals type is not a visual component.

## States

Not applicable: The totals type is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The totals type presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-totals-001 | add-amount, never-mixed | Add 100 hundredths `USD`, 50 `USD` and 200 `EUR`. | USD bucket 150, EUR bucket 200 (test: testKeepsEachCurrencyApart). |
| money-totals-002 | add-totals | Merge a totals holding `USD` 100 into one holding `USD` 50 and `EUR` 20. | `USD` 150, `EUR` 20 (test: testAddingAnotherTotalMergesItsBuckets). |
| money-totals-003 | description-wording, sorted-currencies | Totals of 25,000 `USD` and 4,000 `EUR`, described with the current locale en_US (the description builds each formatter with the default locale). | `€40.00 + $250.00`: the currencies in code order, `EUR` before `USD`, formatted separately (test: testTheDescriptionJoinsEachCurrencyInCodeOrder). |
| money-totals-004 | is-empty, description-wording | Create an empty totals value. | It is empty and its description is the empty string. |
| money-totals-005 | add-sequence | Construct from `[Money(100, USD), Money(250, EUR)]`. | Two buckets; amounts in code order `EUR`, `USD`. |
| money-totals-006 | value-equality | Compare two totals built from the same amounts in different order. | Equal. |

## Edge Cases

- **Null / empty input**: An empty totals value is empty, has no currencies and an empty description.
- **Boundary values**: A bucket can hold a negative or zero figure and still appears, because only the act of adding creates it; adding zero hundredths creates a zero bucket.
- **Concurrent access**: It is a mutable value type with no lock; each owner mutates its own copy.
- **Error states**: No operation fails; integer addition at extreme magnitudes overflows, which traps in Swift; the type adds no guard.
- **Offline / disconnected state**: Not applicable: The totals type has no network access.
- **Cancellation**: Not applicable: The totals type has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The totals type reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The totals type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The totals type contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The totals type presents no UI.

## Feature Flags

Not applicable: The totals type contains no feature-flag reference.

## Analytics

Not applicable: The totals type contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The totals type calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `struct` conforming to `Equatable` and `Sendable` with `private(set)` buckets, built from `some Sequence<Money>`.
- **Compose**: A class over `sortedMapOf<String, Long>()` with `add(Money)` and `toString()` delegating to the formatter per currency.
- **React/Web**: A class over a `Map<string, number>` of integer hundredths, with `currencies()` returning `[...map.keys()].sort()`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `SortedDictionary<string, long>` wrapper with `Add(Money)` and `ToString()`; bind a `TextBlock.Text` to the description property in a billing summary.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Money/MoneyTotals.swift` |

## Design Decisions

**Decision**: The total never converts between currencies.
**Rationale**: No exchange-rate source exists in the toolkit, and a silent conversion would hide the very mixture the buckets exist to keep visible.
**Approved**: pending

**Decision**: The description lists each currency separately rather than one summed figure.
**Rationale**: A reader totaling several clients needs to see each currency's sum; a single number would require a conversion that this type refuses to make.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only buckets hundredths by currency and delegates formatting to the money formatter. `unit-test-coverage` passes because `AgenticToolkitCoreTests/MoneyTotalsTests.swift` covers keeping currencies apart, merging totals, and the code-ordered description.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
