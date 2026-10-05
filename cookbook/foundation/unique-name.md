---
id: 49A8F652-C8FA-4DC6-AFFB-FE834B1E7837
title: "Unique Name"
domain: adtoolkit://cookbook/foundation/unique-name
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Names that read apart from every name already taken: the next free numbered name, and a case- and whitespace-insensitive collision check."
platforms:
  - swift
  - macos
tags:
  - foundation
  - naming
  - uniqueness
  - strings
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Unique Name

## Overview

Names that read apart from every name already taken. It is one rule for every `New Project`, `New Client` and provider configuration: two records with one name read alike in every list, and a chooser that fills by title drops one of them. It offers the first free numbered name when a base is taken, and a collision check that compares the way a person reading a list would, ignoring surrounding whitespace and case.

## Behavioral Requirements

- **base-if-free**: The next name for a base MUST be the base itself when it is not among the taken names (compared exactly).
- **numbered-suffix**: When the base is taken, the next name MUST be the base, a space and the smallest integer from 2 upward whose combined name is not taken (`New Client 2`, `New Client 3`).
- **skips-every-taken-suffix**: The numbering MUST skip every taken suffix and use the first free one, not merely count the taken names.
- **next-compares-exactly**: The next-name search MUST compare names exactly, case and whitespace included.
- **collides-folds**: The collision check MUST compare names after trimming surrounding whitespace and newlines and folding case, and MUST report a collision when any taken name equals the wanted name under that comparison.
- **collides-for-renames**: The collision check is intended for refusing a rename onto another record's name; the caller is responsible for excluding the record being renamed from the taken names.
- **any-sequence**: Both functions MUST accept any sequence of taken names, not only a list.

## Appearance

Not applicable: The name rule is not a visual component.

## States

Not applicable: The name rule is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The name rule presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| unique-name-001 | base-if-free | Base `New Project` with taken names `[]`. | `New Project` (test: testSkipsEveryTakenSuffix, with base `New Client`). |
| unique-name-002 | numbered-suffix | Base `New Project` with taken `["New Project"]`. | `New Project 2` (test: testSkipsEveryTakenSuffix, with base `New Client`). |
| unique-name-003 | skips-every-taken-suffix | Base `New Project` with taken `["New Project", "New Project 2", "New Project 3"]`. | `New Project 4` (test: testSkipsEveryTakenSuffix, with base `misc`). |
| unique-name-004 | skips-every-taken-suffix | Base `X` with taken `["X", "X 3"]`. | `X 2`: the smallest free suffix, not the next after the largest. |
| unique-name-005 | collides-folds | Check `"  alpha "` against taken `["Alpha"]`. | A collision (test: testCollisionIgnoresCaseAndSurroundingWhitespace, with `"acme "` against `["Acme"]`). |
| unique-name-006 | collides-folds | Check `"beta"` against taken `["Alpha"]`. | No collision (test: testCollisionIgnoresCaseAndSurroundingWhitespace covers a non-matching name). |
| unique-name-007 | next-compares-exactly | Base `New project` with taken `["New Project"]`. | `New project`: the exact comparison treats them as different names. |

## Edge Cases

- **Null / empty input**: An empty base is a name like any other: it is returned when free, or becomes ` 2` (a space and the number) when taken. An empty taken collection collides with nothing.
- **Boundary values**: The suffix search is unbounded, so a taken set with many consecutive suffixes costs one set lookup per step; the taken names are put in a set once.
- **Concurrent access**: Stateless pure functions over a caller-supplied snapshot of names; two callers racing on the same snapshot can pick the same name, which the caller must guard.
- **Error states**: Neither function can fail.
- **Offline / disconnected state**: Not applicable: The name rule has no network access.
- **Cancellation**: Not applicable: The name rule has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The name rule reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The name rule defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The name rule contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The name rule presents no UI.

## Feature Flags

Not applicable: The name rule contains no feature-flag reference.

## Analytics

Not applicable: The name rule contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The name rule calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; folding uses `folding(options: [.caseInsensitive], locale: nil)`.
- **Compose**: Top-level functions over `Iterable<String>`; build a `HashSet` once and use `trim().lowercase()` for the collision check.
- **React/Web**: Pure functions over `Iterable<string>` using a `Set`; `trim().toLowerCase()` or `localeCompare` with `sensitivity: 'accent'` for the fold.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers over `IEnumerable<string>` with a `HashSet<string>` for the search and `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` after `Trim()` for the collision check.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/UniqueName.swift` |

## Design Decisions

**Decision**: The next-name search compares exactly while the collision check folds case and whitespace.
**Rationale**: Generating a name from a snapshot only needs to avoid byte-equal duplicates, whereas refusing a rename must stop names that merely read alike in a list.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only chooses and checks names against a supplied set; where names are stored is the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/UniqueNameTests.swift` covers skipping every taken suffix and the case- and whitespace-insensitive collision.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
