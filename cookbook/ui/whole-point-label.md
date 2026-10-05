---
id: 29AB3757-55FC-488F-85F1-4F804E17040B
title: "Whole Point Label"
domain: adtoolkit://cookbook/ui/whole-point-label
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A text label whose intrinsic width is rounded up to a whole point so fractional text widths never clip or truncate."
platforms:
  - swift
  - macos
tags:
  - ui
  - label
  - layout
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/value-row-view
references: []
approved-by: ""
approved-date: ""
---

# Whole Point Label

## Overview

The whole point label is a text label whose intrinsic size is rounded up to whole points. Measured text widths are fractional; when a layout pins a label to exactly that width a fraction short, the text can clip or show an ellipsis. Rounding the width up removes that, so the label always has the room its text needs.

## Behavioral Requirements

- **rounds-width-up**: The label's intrinsic width MUST be the measured width rounded up to the next whole point.
- **keeps-the-height**: The label's intrinsic height MUST be the measured height.
- **passes-through-unknown-width**: When the label has no intrinsic width, it MUST report none rather than a rounded value.
- **behaves-as-a-label**: In every other way the label MUST behave as an ordinary text label.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Intrinsic width is a whole number of points; height is the text's.

## States

| State | Appearance change |
|-------|------------------|
| Default | Ordinary label. |
| Pressed | Not applicable. |
| Disabled | Not applicable. |
| Focused | Not applicable. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: Static text.
- **Accessibility exposure**: Same as an ordinary label.
- **Label requirements**: The text is the label.
- **Announce state changes**: Not applicable.
- **Minimum tap target**: Not applicable: not interactive.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| whole-point-label-001 | rounds-width-up | Label whose measured width is 41.2 | Intrinsic width 42 |
| whole-point-label-002 | rounds-width-up | Label whose measured width is already 40 | Intrinsic width 40 |
| whole-point-label-003 | keeps-the-height | Any label | Intrinsic height equals the measured height |
| whole-point-label-004 | passes-through-unknown-width | A label reporting no intrinsic width | It still reports none |
| whole-point-label-005 | behaves-as-a-label | Set a string on the label | The string shows as in an ordinary label |

## Edge Cases

- **Null/empty input**: An empty string measures zero and stays zero.
- **Boundary values**: A width that is already whole is unchanged.
- **Concurrent access**: Main thread only.
- **Error states**: Not applicable.
- **Offline/disconnected state**: Not applicable.

## Configuration

Not applicable: the label takes the same options as an ordinary label and adds none.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

Not applicable: the label defines no strings; localized text of any length is measured and rounded the same way.

## Accessibility Options

Not applicable: the component applies no animation, color-coded meaning or custom contrast handling of its own, so Reduce Motion, Increase Contrast and Differentiate Without Color need no handling here.

## Feature Flags

Not applicable: no feature-flag check applies; the component behaves the same unconditionally.

## Analytics

Not applicable: the component emits no analytics, tracking or telemetry.

## Privacy

Not applicable: the component collects, stores and transmits no data of its own beyond what the caller hands it for display.

## Logging

Not applicable: the component performs no logging of its own.

## Platform Notes

- **SwiftUI**: Rarely needed: SwiftUI sizes `Text` itself; if a hosted label clips, apply `.fixedSize()` or round the measured width up in a custom `Layout`.
- **Compose**: Compose `Text` rounds to whole pixels; if a custom measurement clips, use `ceil` on the measured width in a `Layout` modifier.
- **React/Web**: Measure with `getBoundingClientRect` and set `Math.ceil(width) + 'px'` as the element's min-width.
- **AppKit / UIKit (source)**: `WholePointLabel` is a public final `NSTextField` subclass overriding `intrinsicContentSize` to return `ceil(width)` with the same height and passing `NSView.noIntrinsicMetric` through. `DisclosureCardView` uses it for its title field.
- **WinUI 3**: Round up the measured width in `MeasureOverride` with `Math.Ceiling` and return that desired size from a custom `TextBlock` host.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/CoreUI/WholePointLabel.swift` |

## Design Decisions

**Decision**: The label has no tests.
**Rationale**: It is a three-line override used by one view; a test would need to measure real text in an AppKit host, which the unit target has not set up for this type.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Separation-of-concerns is passed: the label only adjusts its intrinsic size and holds no layout or settings logic. Unit-test-coverage is failed: no test in the repository's test targets references `WholePointLabel`, so none of the vectors is executed.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
