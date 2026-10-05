---
id: A1563AD8-D4E4-44F0-9823-3D9229C9321D
title: "Billing Rounding"
domain: adtoolkit://cookbook/foundation/billing/billing-rounding
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Turns raw tracked seconds into billed seconds, rounding once per entry to a configured increment."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - rounding
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-clock
  - adtoolkit://cookbook/foundation/billing/billing-rollup
references: []
approved-by: ""
approved-date: ""
---

# Billing Rounding

## Overview

A stateless function that converts raw tracked seconds into billed seconds by rounding to a whole number of minute increments. It is applied once, at entry level: rounding each segment and summing would bill five five-minute bursts as 75 minutes instead of 30. The rounding arithmetic belongs to the shared increment-rounding utility; this type only maps billing's two stored knobs (increment minutes and mode) onto it.

## Behavioral Requirements

- **round-to-increment**: The function MUST return `rawSeconds` rounded to a whole multiple of `roundingMinutes` minutes.
- **mode-up**: Mode `up` MUST round to the next increment, leaving an exact multiple unchanged.
- **mode-nearest**: Mode `nearest` MUST round half-up to the closest increment.
- **unknown-mode-up**: Any other mode string MUST behave as `up`, the default, rather than billing nothing.
- **non-positive-increment-passthrough**: A `roundingMinutes` of zero or less MUST mean no rounding: the raw seconds pass through unchanged.
- **non-positive-raw-zero**: Zero or negative raw seconds MUST bill zero, so a session with no time never acquires a minimum increment.
- **once-per-entry**: Callers MUST apply rounding to an entry's total raw seconds, not to each segment.

## Appearance

Not applicable — this is a pure arithmetic function, not a visual component.

## States

Not applicable — this is a pure arithmetic function, not a visual component.

## Accessibility

Not applicable — this is a pure arithmetic function, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rounding-001 | mode-up | 1s, 15 min, `up` | 900 |
| billing-rounding-002 | mode-up | 901s, 15 min, `up` | 1800 |
| billing-rounding-003 | mode-nearest | 420s, 15 min, `nearest` | 0 |
| billing-rounding-004 | mode-nearest | 450s, 15 min, `nearest` | 900 |
| billing-rounding-005 | non-positive-increment-passthrough | 437s, 0 min, `up` | 437 |
| billing-rounding-006 | non-positive-increment-passthrough | 437s, -5 min, `up` | 437 |
| billing-rounding-007 | non-positive-raw-zero | -5s, 15 min, `up` | 0 |
| billing-rounding-008 | unknown-mode-up | 1s, 15 min, `sideways` | 900 |
| billing-rounding-009 | once-per-entry | five 300s segments rounded each at 15 min `up`, summed | 4500 (the wrong way) |
| billing-rounding-010 | once-per-entry | the same five segments totalled (1500s) then rounded | 1800 |

## Edge Cases

- A raw value exactly on an increment boundary is unchanged in `up` mode.
- Mode matching is exact and case-sensitive; `Up` falls back to `up`.
- The function never throws and never returns a negative value.

## Configuration

None: a pure arithmetic function takes no configuration beyond the values passed to each call.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the function has no view layer.
- **Compose**: A top-level or companion function over `Int`; use `Math.ceil`-style integer arithmetic, not floating point.
- **React/Web**: A pure function over `number`; use `Math.ceil` and `Math.floor(x + 0.5)` on integers, never fractional minutes.
- **AppKit / UIKit**: Plain Swift; the mode string is mapped through `IncrementRounding(rawValue:)` with `.upward` as the default.
- **WinUI 3**: A static method over `int` / `long`; use integer division and `Math.DivRem`, not `double`, to avoid rounding drift.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingRounding.swift` |

## Design Decisions

**Decision**: The mode is a free-form string rather than an enum at this boundary.
**Rationale**: The stored setting and the wire carry a string; a typed enum would reject older values. Unknown values fall back to `up`; tightening this would need a settings migration.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: only the knob-to-rule mapping lives here; the arithmetic is the shared increment-rounding utility. unit-test-coverage passes: `BillingRoundingTests` covers up, nearest, zero increment, zero raw, unknown mode and `testRoundingOncePerEntryNotPerSegment`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
