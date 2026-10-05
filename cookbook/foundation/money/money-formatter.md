---
id: F1868607-3458-427A-B784-B05BE97C7E8F
title: "Money Formatter"
domain: adtoolkit://cookbook/foundation/money/money-formatter
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Renders integer hundredths as locale-aware currency text and parses typed amounts back, without ever using a floating-point number."
platforms:
  - swift
  - macos
tags:
  - foundation
  - money
  - formatting
  - parsing
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money
  - adtoolkit://cookbook/foundation/money/money-totals
references: []
approved-by: ""
approved-date: ""
---

# Money Formatter

## Overview

Renders integer hundredths as currency text and reads typed amounts back. It is the only integer-to-string bridge for money: nothing else may format an amount through a floating-point number. The integer is always hundredths of the currency's major unit whatever that currency's own minor unit is, so parsing multiplies by 100 and display divides by 100 for every currency, and the two agree for currencies with no minor unit or three. Display always shows exactly two fraction digits, so rows added up equal the total. Parsing is forgiving about what people paste, deciding which of the period and comma is the decimal point from the text and the locale, and returns nothing, never a plausible wrong number, for anything it cannot read unambiguously.

## Behavioral Requirements

- **integer-hundredths**: The formatter MUST take and return amounts as integer hundredths of the major unit and MUST NOT require a floating-point number to exist at any step.
- **construction**: The formatter MUST be built from a currency code (default `USD`) and a locale (default the current locale); the locale decides symbol placement, grouping and the decimal separator.
- **display-two-fraction-digits**: Display MUST always show exactly two fraction digits for every currency, with the currency symbol and grouping, so rounded rows add up to the exactly-summed total and no currency acquires a third digit the stored value never had.
- **display-money-uses-own-currency**: Formatting a money value MUST follow that value's own currency, not the formatter's default.
- **editable-string**: The editable form MUST be a plain number with two fraction digits, no currency symbol and no grouping, in the locale's decimal separator, suitable for a text field while someone is typing.
- **parse-accepts-pasted-text**: Parsing MUST accept a currency symbol or code, grouping separators, surrounding spaces and either decimal separator.
- **parse-both-separators**: When both a period and a comma are present, the last separator MUST be the decimal point and the other kind MUST group; the decimal kind MUST appear exactly once.
- **parse-repeated-separator-groups**: When one kind of separator appears more than once, it MUST group and there is no decimal point.
- **parse-single-separator**: When one separator appears once: if it is the locale's decimal separator it MUST be a decimal point; if it is the locale's grouping separator it MUST group only when exactly three digits follow it and a non-zero integer part precedes it, and otherwise MUST be a decimal point.
- **parse-ambiguous-refused**: A single separator that is neither of the locale's separators, with exactly three digits after it and a non-zero integer part, MUST be refused as ambiguous.
- **parse-grouping-in-threes**: Grouping MUST be in groups of exactly three digits after a leading group of one to three, and all before the decimal point; otherwise parsing MUST return nothing.
- **parse-sign**: A leading hyphen-minus or Unicode minus sign MUST make the amount negative; a leading plus MUST be ignored; a sign after any digit or separator MUST be refused.
- **parse-no-digits-refused**: Text with no digits, including a lone sign or a lone currency symbol, MUST return nothing rather than zero.
- **parse-half-up**: More than two fraction digits MUST round half-up to hundredths using decimal arithmetic, not binary floating point.
- **parse-overflow-refused**: An amount too large for the integer width MUST return nothing instead of wrapping.
- **parse-stray-characters**: Letters, whitespace, apostrophes and currency symbols MUST be ignored; any other character MUST make the text unreadable.

## Appearance

Not applicable: The formatter is not a visual component.

## States

Not applicable: The formatter is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The formatter presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-formatter-001 | display-two-fraction-digits | Format 0, 3,125 and 123,456,789 hundredths in an en_US `USD` formatter. | `$0.00`, `$31.25`, `$1,234,567.89` (test: testFormatterRendersIntegerCents). |
| money-formatter-002 | editable-string | Editable string for 3,125 and 123,456,789. | `31.25` and `1234567.89` (test: testEditableStringHasNoSymbolAndNoGrouping). |
| money-formatter-003 | parse-accepts-pasted-text | Parse `150`, `150.5`, `$1,250.00`, ` 31.25 ` in en_US. | 15,000; 15,050; 125,000; 3,125 (test: testParsingAcceptsWhatPeopleActuallyType). |
| money-formatter-004 | parse-half-up | Parse `150.555` and `150.554`. | 15,056 and 15,055 (test: testParsingRoundsHalfUpRatherThanTruncating). |
| money-formatter-005 | parse-single-separator | In en_US parse `150,50` and `1,250`; in de_DE parse `150.50` and `1.250`. | 15,050 and 125,000; 15,050 and 125,000 (tests: testACommaDecimalIsHonouredInAnEnglishLocale, testADotDecimalIsHonouredInAGermanLocale). |
| money-formatter-006 | parse-ambiguous-refused | In fr_FR parse `1.250` and `1.25`. | Nothing, then 125 (test: testAnAmbiguousSeparatorIsRefused). |
| money-formatter-007 | parse-both-separators | In de_DE parse `1.250,00`; in en_US parse `1,250.00`. | 125,000 for each. |
| money-formatter-008 | parse-grouping-in-threes, parse-repeated-separator-groups | In en_US parse `1.2.5`, `15..50`, `12,34,567`, `1,250.00.5`. | Nothing for each (test: testMalformedAmountsAreRefused). |
| money-formatter-009 | parse-sign | Parse `\u22125` and `-5`. | -500 for each (test: testUnicodeMinusIsNegative). |
| money-formatter-010 | parse-no-digits-refused | Parse the empty string, `-` and `$`. | Nothing for each (test: testParsingRejectsTextWithNoDigits). |
| money-formatter-011 | parse-overflow-refused | Parse `99999999999999999999`. | Nothing (test: testAnOverflowingAmountIsRefused). |

## Edge Cases

- **Null / empty input**: Empty text parses to nothing; a zero amount displays as `0.00` with the symbol.
- **Boundary values**: A leading decimal point (`.5`) and a trailing one (`150.`) are accepted; a separator at either end of a run of separators is refused. A single group of exactly three digits after a non-zero integer part is treated as grouping in locales that group with that character.
- **Concurrent access**: The formatter holds only a currency code and a locale and is an immutable value, safe to share.
- **Error states**: Parsing returns nothing for every malformed input and never an approximation; display cannot fail.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| currency | ISO-4217 text | `USD` | The code used for the symbol. |
| locale | locale | current locale | Decides symbol placement, grouping and the decimal separator. |

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

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. Display uses `Decimal.formatted(.currency(code:).precision(...).locale(...))`, and parsing rounds with `NSDecimalRound(.plain)`.
- **Compose**: Use `NumberFormat.getCurrencyInstance(locale)` with `setMinimumFractionDigits(2)` and `setMaximumFractionDigits(2)` and `BigDecimal` for parsing; reimplement the separator rules in a pure function because `NumberFormat.parse` accepts partial strings.
- **React/Web**: `Intl.NumberFormat(locale, {style: 'currency', currency, minimumFractionDigits: 2, maximumFractionDigits: 2})` for display, with the integer divided by 100 via string arithmetic, not a float; port the parse rules as a pure function using `Intl.NumberFormat().formatToParts` to learn the locale's separators.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use `decimal` with `ToString("C2", cultureInfo)` and `NumberFormatInfo.NumberDecimalSeparator`/`CurrencyGroupSeparator` to learn the locale's separators; a `TextBox` with a `TextChanging` handler can call the parser and keep the last good value when it returns null.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Money/MoneyFormatter.swift` |

## Design Decisions

**Decision**: Display always uses two fraction digits, whatever the currency's own minor unit.
**Rationale**: Letting the currency choose would round whole-unit currencies row by row while a total is formatted from the exact sum, so rows would not add up, and would give three-digit currencies a digit the stored value never had.
**Approved**: pending

**Decision**: Parsing decides the decimal separator from the text, not from the locale alone.
**Rationale**: A field that rejects an amount pasted from an email is a field people stop using, so the parser accepts either convention and refuses only the genuinely ambiguous case, because guessing there is how a rate ends up a thousand times too large.
**Approved**: pending

**Decision**: Unparseable text returns nothing rather than zero.
**Rationale**: A half-typed minus sign treated as zero would wipe the rate mid-keystroke; nothing lets the caller keep the previous value.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |

`separation-of-concerns` passes because the type only converts between integer hundredths and text; arithmetic is in the money type and per-currency totals in the totals spec. `unit-test-coverage` passes because `AgenticToolkitCoreTests/MoneyTests.swift` covers display, the editable form, parsing of pasted text, half-up rounding, the locale cases, ambiguity refusal, malformed amounts, the Unicode minus and overflow; the macOS field view tests additionally exercise it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
