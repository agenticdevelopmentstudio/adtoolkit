---
id: CC43F118-215C-4794-BB67-6D97BAB9DFE4
title: "UTF-8 Search"
domain: adtoolkit://cookbook/foundation/utf8-search
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A byte-level substring test on a string's own UTF-8 storage, for hot prefilters over large files."
platforms:
  - swift
  - macos
tags:
  - foundation
  - strings
  - search
  - performance
depends-on: []
related:
  - adtoolkit://cookbook/foundation/core-utilities
references: []
approved-by: ""
approved-date: ""
---

# UTF-8 Search

## Overview

A substring test that finds a needle's UTF-8 bytes inside a string's own UTF-8 storage with a raw memory search. It is for prefilters that run on every line of a large file: the generic substring search walks indices a character at a time, and on a 130 MB transcript that search was nearly all of the scan. A byte match is exact for any needle, because UTF-8 never lets one character's bytes start inside another's. A hot needle should be held as bytes and passed as such to avoid re-encoding.

## Behavioral Requirements

- **contains-bytes**: The test MUST report whether the string's UTF-8 bytes contain the needle's bytes as a contiguous run.
- **empty-needle**: An empty needle MUST be contained in every string, including the empty string.
- **empty-haystack**: A non-empty needle MUST NOT be found in an empty string.
- **exact-for-any-needle**: The match MUST be byte-exact and therefore correct for any needle, including multi-byte characters, with no normalization, case folding or locale.
- **string-needle-overload**: A needle given as a string MUST behave exactly as the same string's UTF-8 bytes given as the byte form.
- **hot-path-bytes**: Callers with a hot needle SHOULD hold it as a byte array and pass that form, so the needle is encoded once.
- **no-copy-of-contents**: The search MUST run on the string's own contiguous storage and MUST NOT build an intermediate character array.

## Appearance

Not applicable: The search helper is not a visual component.

## States

Not applicable: The search helper is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The search helper presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utf8-search-001 | contains-bytes | Search a line for the needle `"type":"summary"` (quote characters included). | True when the line contains it (test: testFindsANeedleByItsBytes). |
| utf8-search-002 | exact-for-any-needle | Search a line for the bytes of `résumé`. | True when present, since multi-byte characters match exactly (test: testFindsANeedleByItsBytes). |
| utf8-search-003 | contains-bytes | Search a line for `assistant` when absent. | False (test: testFindsANeedleByItsBytes). |
| utf8-search-004 | empty-needle | Search any line for the empty needle. | True (test: testFindsANeedleByItsBytes). |
| utf8-search-005 | empty-haystack | Search the empty string for `x`. | False (test: testFindsANeedleByItsBytes). |
| utf8-search-006 | string-needle-overload | Search the same line using the string form and the byte form of one needle. | The same answer both ways. |

## Edge Cases

- **Null / empty input**: Empty needle is always found; empty string never contains a non-empty needle.
- **Boundary values**: A needle longer than the string is not found; a needle equal to the whole string is found. The search is not aware of grapheme boundaries, so a needle that is a bare combining mark matches inside a longer character.
- **Concurrent access**: The search reads an immutable value copy and shares no state.
- **Error states**: It cannot fail.
- **Offline / disconnected state**: Not applicable: The search helper has no network access.
- **Cancellation**: Not applicable: The search helper has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The search helper reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The search helper defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The search helper contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The search helper presents no UI.

## Feature Flags

Not applicable: The search helper contains no feature-flag reference.

## Analytics

Not applicable: The search helper contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The search helper calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `String` extension that copies the string so `withUTF8` can make it contiguous and calls `memmem` on the buffer.
- **Compose**: On the JVM use `String.contains` on a `ByteArray` search via `ByteBuffer`; for hot paths over large files, search raw `ByteArray` lines with a Boyer-Moore-style search and skip decoding.
- **React/Web**: Search `Uint8Array` buffers with `Buffer.indexOf` in Node, which is byte-exact and fast, and skip decoding to a string for lines that do not match.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Search `ReadOnlySpan<byte>` with `MemoryExtensions.IndexOf(span, needleSpan)`, which is vectorized, after encoding the text once with `Encoding.UTF8.GetBytes`; avoid `string.Contains`, which is culture-sensitive unless `StringComparison.Ordinal` is passed.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/UTF8Search.swift` |

## Design Decisions

**Decision**: Matching is byte-level, with no Unicode normalization.
**Rationale**: Normalization would reintroduce the per-character walk the type exists to avoid; callers that need canonically equivalent matching normalize before searching.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the extension only answers whether bytes occur; what a hit means is the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/UniqueNameTests.swift` includes a test that finds a needle by its bytes, a multi-byte needle, an absent needle, the empty needle and the empty haystack (the test shares a file with the unique-name tests).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
