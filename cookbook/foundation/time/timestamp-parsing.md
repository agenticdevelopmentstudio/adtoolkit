---
id: 29A3044C-F785-4FA3-A1B9-746D069AE198
title: "Timestamp Parsing"
domain: adtoolkit://cookbook/foundation/time/timestamp-parsing
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one parser that accepts every timestamp shape across a daemon, its app and its command-line tool: ISO 8601 with and without fractional seconds, and SQLite datetime text."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - parsing
  - timestamps
depends-on: []
related:
  - adtoolkit://cookbook/foundation/time/utc-timestamp
  - adtoolkit://cookbook/foundation/time/local-time-text
references: []
approved-by: ""
approved-date: ""
---

# Timestamp Parsing

## Overview

The one timestamp parser for the whole system. Timestamps arrive in three shapes across a daemon, its app and its command-line tool, and every subsystem must accept all of them: ISO 8601 with fractional seconds (`2026-04-14T10:00:00.123Z`), plain ISO 8601 (`2026-04-14T10:00:00Z`), and the text a SQLite `datetime()` call produces (`2026-04-14 10:00:00`, UTC, space-separated), which is what the database stores and the shape the standard ISO 8601 formatter silently cannot parse. Before this existed about six sites hand-rolled a try-fractional-then-plain parser and most omitted the SQLite shape, so they silently failed on stored timestamps, which was the bug behind a monitor's idle minutes always reading zero. Parsing through here fixes that class of bug in one place.

## Behavioral Requirements

- **three-shapes**: The parser MUST accept ISO 8601 with fractional seconds and a zone designator, plain ISO 8601 with a zone designator, and the SQLite text shape `yyyy-MM-dd HH:mm:ss` interpreted as UTC.
- **try-order**: The parser MUST try the fractional ISO shape first, then the plain ISO shape, then the SQLite shape, and return the first that parses.
- **sqlite-is-utc**: The SQLite shape carries no zone and MUST be read as UTC.
- **empty-is-nothing**: Empty text MUST return nothing.
- **unparseable-is-nothing**: Text that matches none of the shapes MUST return nothing, never a default date.
- **fractional-equals-plain-plus-fraction**: A fractional ISO timestamp MUST equal the plain timestamp of the same second plus the fraction.
- **shared-formatters**: The parser MUST reuse shared, never-mutated formatter instances rather than building one per call.
- **single-parser**: Every subsystem MUST parse through this one function; no site hand-rolls its own.

## Appearance

Not applicable: The parser is not a visual component.

## States

Not applicable: The parser is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The parser presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| timestamp-parsing-001 | three-shapes, fractional-equals-plain-plus-fraction | Parse `2026-04-14T10:00:00.500Z` and `2026-04-14T10:00:00Z`. | The first is the second plus 0.5 seconds (test: testFractionalMatchesPlainPlusFraction). |
| timestamp-parsing-002 | three-shapes, sqlite-is-utc | Parse `2026-04-14 10:00:00`. | The instant 2026-04-14T10:00:00Z, epoch 1776160800 (test: testSQLiteDateTimeParsedAsUTC). |
| timestamp-parsing-003 | empty-is-nothing | Parse the empty string. | Nothing (test: testEmptyAndGarbageAreNil). |
| timestamp-parsing-004 | unparseable-is-nothing | Parse `not a date` and `2026-13-99`. | Nothing (test: testEmptyAndGarbageAreNil). |
| timestamp-parsing-005 | try-order | Parse `2026-04-14T10:00:00Z`. | Parsed by the plain ISO shape after the fractional one declines. |
| timestamp-parsing-006 | three-shapes | Parse `2026-04-14T10:00:00+02:00`. | The instant 2026-04-14T08:00:00Z: a numeric zone offset is accepted by the ISO shape. |

## Edge Cases

- **Null / empty input**: Empty text returns nothing; whitespace-only text matches no shape and returns nothing.
- **Boundary values**: A SQLite timestamp with fractional seconds does not match the SQLite shape here; the UTC timestamp spec adds a fast path for the millisecond form. A date without a time matches none of the shapes.
- **Concurrent access**: The shared formatters are configured once and never mutated, so any thread may parse.
- **Error states**: No error is thrown; failure is nothing.
- **Offline / disconnected state**: Not applicable: The parser has no network access.
- **Cancellation**: Not applicable: The parser has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The parser reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The parser defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The parser contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The parser presents no UI.

## Feature Flags

Not applicable: The parser contains no feature-flag reference.

## Analytics

Not applicable: The parser contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The parser calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It uses two `ISO8601DateFormatter` instances held as `nonisolated(unsafe)` statics and a `DateFormatter` with a POSIX locale and a UTC zone for the SQLite shape.
- **Compose**: Use `java.time.Instant.parse` for the two ISO shapes and a `DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").withZone(UTC)` for SQLite; `OffsetDateTime.parse` accepts numeric offsets.
- **React/Web**: `Date.parse` accepts the ISO shapes but treats the space-separated form as local time in some engines; normalize the SQLite shape by replacing the space with `T` and appending `Z` before parsing.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: `DateTimeOffset.TryParse` with `DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal` and `CultureInfo.InvariantCulture` handles all three shapes; use `TryParseExact` for the SQLite pattern to avoid locale guesses.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Time/TimestampParsing.swift` |

## Design Decisions

**Decision**: The SQLite shape is parsed by a dedicated fixed-format reader read as UTC.
**Rationale**: The standard ISO 8601 formatter silently cannot parse the space-separated form, which is what stored rows hold, so a dedicated reader is the only way to keep one parser for all three shapes.
**Approved**: pending

**Decision**: The shared formatters are held in unchecked statics.
**Rationale**: The platform marks the ISO formatter as not safe to share even though it is safe to parse with once configured; the statics are never mutated after creation, so the opt-out is sound, and building a formatter per call would be far slower.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only turns text into an instant; writing the wire form and fast-path parsing are in the UTC timestamp spec. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Time/TimestampParsingTests.swift` covers fractional versus plain, the SQLite shape read as UTC, and empty and garbage text.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
