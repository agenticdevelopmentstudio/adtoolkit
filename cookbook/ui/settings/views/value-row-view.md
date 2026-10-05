---
id: D0AA6237-E5D7-4CF8-A1CB-621033575421
title: "Value Row View"
domain: adtoolkit://cookbook/ui/settings/views/value-row-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A read-only settings row showing a title on the left and a right-aligned, selectable value on the right."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - row
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/money-field-view
references: []
approved-by: ""
approved-date: ""
---

# Value Row View

## Overview

The value row is a read-only settings row. It shows a title and a value side by side; the value is right-aligned, uses monospaced digits so changing numbers do not shift the layout, and can be selected for copying. It has no way to edit the value.

## Behavioral Requirements

- **shows-title-and-value**: The row MUST show the title it was built with and the initial value.
- **value-is-settable**: The row MUST expose its value as a property that reads the text on screen and replaces it when assigned.
- **value-is-read-only-to-user**: The user MUST NOT be able to edit the value.
- **value-is-selectable**: The user MUST be able to select the value text for copying.
- **value-is-right-aligned**: The value MUST be right-aligned.
- **value-uses-monospaced-digits**: The value MUST use monospaced digits.
- **value-is-labelled-by-title**: The value MUST expose the row's title as its accessibility label, so assistive technology reads the pair as one.
- **pins-content-to-edges**: The row MUST fill its own bounds with its content and rely on its container for width.
- **is-settings-view**: The row MUST be usable anywhere a settings view is expected.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None.
- **Padding**: None of its own; the container supplies spacing, and the row spacing token separates title and value.
- **Font**: Title in the primary text style; value in the same size with monospaced digits.
- **Background**: None; the row is transparent over its container.
- **Foreground/Text**: Both labels take their colors from the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: No fixed size; the value takes the remaining width after the title.

## States

| State | Appearance change |
|-------|------------------|
| Default | Title left, value right. |
| Pressed | Not applicable: the row is not a control. |
| Disabled | Not applicable: the row has no disabled state. |
| Focused | The value text can take selection but the row defines no focus appearance of its own. |
| Loading | Not applicable: no loading state. |

## Accessibility

- **Role/trait**: The value is exposed as static text.
- **Accessibility exposure**: The value is exposed with the title as its label.
- **Label requirements**: The title MUST be non-empty for the label to be meaningful.
- **Announce state changes**: Not applicable: assistive technology re-reads the value when the caller changes it.
- **Minimum tap target**: Not applicable: the row is not interactive.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| value-row-view-001 | shows-title-and-value | Build with title Version and value 1.2.3 | The title reads Version and the value reads 1.2.3 |
| value-row-view-002 | value-is-settable | Assign 2.0 to the value property | The shown text and the property both read 2.0 |
| value-row-view-003 | value-is-selectable | Inspect the value text | It is selectable and not editable |
| value-row-view-004 | value-is-labelled-by-title | Read the value's accessibility label | It equals the title |
| value-row-view-005 | value-uses-monospaced-digits | Inspect the value's font | Its digits are monospaced |
| value-row-view-006 | value-is-right-aligned | Inspect the value's alignment | It is right-aligned |
| value-row-view-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty value shows nothing; an empty title leaves the accessibility label empty.
- **Boundary values**: A very long value is the caller's concern; the row sets no truncation policy beyond the label's defaults.
- **Concurrent access**: Main thread only.
- **Error states**: Not applicable: no failure path.
- **Offline/disconnected state**: Not applicable: no networking.

## Configuration

Not applicable beyond construction: the row takes a title and an initial value; the value can be reassigned later.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

Not applicable: the row defines no strings; the caller supplies title and value already localized.

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

- **SwiftUI**: `LabeledContent(title) { Text(value).monospacedDigit().textSelection(.enabled) }` is the direct equivalent.
- **Compose**: A `Row` with a `Text(title)` and a right-aligned `SelectionContainer { Text(value, fontFeatureSettings = "tnum") }`.
- **React/Web**: A `<div>` holding a label and an `<output>` with `font-variant-numeric: tabular-nums; text-align: right; user-select: text`, tied together with `aria-labelledby`.
- **AppKit / UIKit (source)**: `ComposableSettings.ValueRowView` is an `@MainActor` view conforming to `SettingsViewProtocol`, built from `makeRowLabel`, `makeValueLabel`, `makeRow` and `pinToEdges`. Both labels are `ThemedLabel`s exposed as `label` and `valueLabel`; `value` reads and writes `valueLabel.stringValue`. The value label is selectable, right-aligned, uses monospaced digits and has the title as its accessibility label. `init(coder:)` is unavailable.
- **WinUI 3**: A `Grid` with two `TextBlock`s, the second `HorizontalAlignment="Right"`, `IsTextSelectionEnabled="True"` and `FontFeatures` tabular numerals, with `AutomationProperties.Name` set to the title.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/ValueRowView.swift` |

## Design Decisions

**Decision**: The value is plain text only; there is no copy button or formatting hook.
**Rationale**: Selection is enough for the current read-only rows; richer formatting stays with the caller who builds the string.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the row only lays out two themed labels and holds no settings or storage logic. Unit-test-coverage is partial: `ValueRowViewTests.swift` covers the title and value and the accessibility label and selectability, but not the alignment or monospaced digits.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
