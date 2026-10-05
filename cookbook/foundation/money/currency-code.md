---
id: B8C3DBF6-F3EE-4346-AC87-542A4FBF7917
title: "Currency Code"
domain: adtoolkit://cookbook/foundation/money/currency-code
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shape rule for an ISO-4217 currency code: three ASCII letters, trimmed and upper-cased."
platforms:
  - swift
  - macos
tags:
  - foundation
  - money
  - currency
  - validation
depends-on: []
related:
  - adtoolkit://cookbook/foundation/money
references: []
approved-by: ""
approved-date: ""
---

# Currency Code

## Overview

The one shape rule for an ISO-4217 currency code, kept in a single place so a code one screen refuses is never accepted by another. Given typed or stored text, it returns the code trimmed of surrounding whitespace and upper-cased, or nothing if the text is not three ASCII letters. Only the shape is checked: whether the code is in circulation is not.

## Behavioral Requirements

- **trim-and-uppercase**: Normalizing MUST trim surrounding whitespace and newlines and upper-case the text before checking it.
- **three-letters**: The normalized text MUST be exactly three characters, each an ASCII letter `A` to `Z`; anything else MUST yield nothing.
- **shape-only**: Normalizing MUST NOT check the code against any list of real currencies; `XYZ` is accepted.
- **single-owner**: This shape rule MUST be the only one used to accept a currency code, so no screen accepts a code another refuses.

## Appearance

Not applicable: The currency code rule is not a visual component.

## States

Not applicable: The currency code rule is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The currency code rule presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| currency-code-001 | trim-and-uppercase | Normalize ` usd `. | `USD` (test: CurrencyCodeTests in MoneyTotalsTests.swift). |
| currency-code-002 | three-letters | Normalize `EUR`. | `EUR`. |
| currency-code-003 | three-letters | Normalize `U5D`. | Nothing: a digit is not a letter. |
| currency-code-004 | three-letters | Normalize `US` and `EURO`. | Nothing for each: wrong length. |
| currency-code-005 | three-letters | Normalize the empty string. | Nothing. |
| currency-code-006 | shape-only | Normalize `xyz`. | `XYZ`. |

## Edge Cases

- **Null / empty input**: Empty or whitespace-only text yields nothing.
- **Boundary values**: Exactly three letters pass; two or four fail. A non-ASCII letter such as an accented one fails because only `A` to `Z` are accepted after upper-casing; the check runs after upper-casing, so a letter whose upper-case form expands to ASCII letters (such as `ß`, which becomes `SS`) can still yield a three-letter code.
- **Concurrent access**: It is a stateless pure function.
- **Error states**: It never fails; invalid text returns nothing.
- **Offline / disconnected state**: Not applicable: The currency code rule has no network access.
- **Cancellation**: Not applicable: The currency code rule has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The currency code rule reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The currency code rule defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The currency code rule contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The currency code rule presents no UI.

## Feature Flags

Not applicable: The currency code rule contains no feature-flag reference.

## Analytics

Not applicable: The currency code rule contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The currency code rule calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with one static function.
- **Compose**: A top-level function using `trim().uppercase()` and a `Regex("[A-Z]{3}")` full match; `java.util.Currency.getInstance` would also check membership, which this rule deliberately does not.
- **React/Web**: A pure function `text.trim().toUpperCase()` tested against `/^[A-Z]{3}$/`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A static helper using `Trim().ToUpperInvariant()` and a check that all three characters are in the range `A` to `Z`; use the invariant culture so the Turkish dotless-i rule cannot change the result.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Money/CurrencyCode.swift` |

## Design Decisions

**Decision**: Only the shape is checked, not membership in the ISO-4217 list.
**Rationale**: A bundled list would age and would refuse a code a bank has introduced; the shape check catches typos and wrong-length text, which is what the entry screens need.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the function only normalizes the shape of a code; formatting and arithmetic are elsewhere. `unit-test-coverage` passes because `CurrencyCodeTests` in `AgenticToolkitCoreTests/MoneyTotalsTests.swift` asserts the trim-and-upper-case path and rejection of `U5D`, `US`, `EURO` and the empty string.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
