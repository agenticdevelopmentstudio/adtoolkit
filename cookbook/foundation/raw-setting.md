---
id: A8BFCD0B-0759-4801-AAF6-A14D7AA3FE49
title: "Raw Setting"
domain: adtoolkit://cookbook/foundation/raw-setting
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One set of rules for reading a setting stored as text into a boolean, a clamped integer or a non-empty string, with a default for anything absent or malformed."
platforms:
  - swift
  - macos
tags:
  - foundation
  - settings
  - parsing
  - defaults
depends-on: []
related:
  - adtoolkit://cookbook/foundation/settings-storage
references: []
approved-by: ""
approved-date: ""
---

# Raw Setting

## Overview

Reads a setting stored as text, such as a settings-table row or an environment variable, into the value it means, falling back to a default for anything absent or malformed. It is one set of rules so the same garbage string never reads true in one feature and false in another. Booleans accept a fixed set of spellings, integers are clamped into an allowed range, and strings are trimmed and fall back when empty.

## Behavioral Requirements

- **bool-true-spellings**: A boolean read MUST return true for `1`, `true`, `yes` and `on`, compared case-insensitively after trimming whitespace and newlines.
- **bool-false-spellings**: A boolean read MUST return false for `0`, `false`, `no` and `off`, under the same comparison.
- **bool-fallback**: A boolean read of text that is absent, empty or any other spelling MUST return the caller's default, so a caller whose safe answer is off passes false.
- **int-parses-trimmed**: An integer read MUST trim whitespace and newlines and parse a base-ten integer; text that is absent or not an integer MUST return the caller's default.
- **int-clamps-to-range**: An integer read that parses MUST be clamped into the caller's closed range rather than refused, so an over-eager hand edit means the nearest allowed value.
- **int-default-not-clamped**: The default returned for absent or malformed integer text MUST be returned as given, without clamping.
- **string-trims**: A string read MUST return the text trimmed of whitespace and newlines.
- **string-fallback**: A string read MUST return the caller's default when the text is absent or empty after trimming.
- **stateless**: The functions MUST hold no state.

## Appearance

Not applicable: The reader is not a visual component.

## States

Not applicable: The reader is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The reader presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| raw-setting-001 | bool-true-spellings | Read `" YES "`, `"On"`, `"1"` with default false. | True for each (test: testBoolReadsEverySpellingAndFallsBackOnGarbage). |
| raw-setting-002 | bool-false-spellings | Read `"off"`, `"No"`, `"0"` with default true. | False for each. |
| raw-setting-003 | bool-fallback | Read absent, empty and `"maybe"` with default true, then with default false. | The default each time. |
| raw-setting-004 | int-clamps-to-range | Read `"500"` with range 1 to 100 and default 10. | 100 (test: testIntClampsIntoRangeAndFallsBackWhenAbsent). |
| raw-setting-005 | int-parses-trimmed, int-default-not-clamped | Read absent, `"abc"` and `"1.5"` with range 1 to 100 and default 10. | 10 each time. |
| raw-setting-006 | string-trims, string-fallback | Read `"  hello "`, `"   "` and absent with default `x`. | `hello`, `x`, `x` (test: testStringTrimsAndFallsBackWhenEmpty). |

## Edge Cases

- **Null / empty input**: Absent and empty text always yield the caller's default for all three readers.
- **Boundary values**: A value equal to either bound of the range is returned as is; a negative integer is parsed and clamped like any other.
- **Concurrent access**: The functions are stateless and safe to call from any thread.
- **Error states**: No function fails; malformed text becomes the default.
- **Offline / disconnected state**: Not applicable: The reader has no network access.
- **Cancellation**: Not applicable: The reader has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| default | boolean, integer or text | none, required | The value returned for absent or malformed text. |
| range | closed integer range | none, required for integers | The bounds an integer read is clamped into. |

The reader reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The reader defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The reader contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The reader presents no UI.

## Feature Flags

Not applicable: The reader contains no feature-flag reference.

## Analytics

Not applicable: The reader contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The reader calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with three static functions.
- **Compose**: Top-level functions `rawBool`, `rawInt` and `rawString` using `trim().lowercase()` and `coerceIn`.
- **React/Web**: Three pure functions; use `Number.parseInt` only after a `/^-?\d+$/` check, because `parseInt('12abc')` would accept trailing text.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers using `string.Trim()`, `int.TryParse` with `NumberStyles.Integer` and `CultureInfo.InvariantCulture`, and `Math.Clamp`; read raw text from `ApplicationData` settings or environment variables.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/SettingStorage/RawSetting.swift` |

## Design Decisions

**Decision**: Out-of-range integers are clamped rather than treated as malformed.
**Rationale**: A hand-edited value that is too large still expresses an intent toward the high end; clamping keeps that intent while staying inside what the feature supports.
**Approved**: pending

**Decision**: Unrecognized boolean spellings fall back to the default instead of false.
**Rationale**: Each call site knows its own safe answer, so the caller supplies it; a global false would turn a garbled enable-flag into off even where on is the safe state.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only converts raw text to typed values; where the text comes from is the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/SettingsStore/RawSettingTests.swift` has tests for every spelling of the boolean and its fallback, integer clamping and fallback, and string trimming and fallback.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
