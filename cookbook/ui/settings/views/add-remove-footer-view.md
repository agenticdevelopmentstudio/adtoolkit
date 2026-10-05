---
id: A1D787E2-2E3F-4742-A30B-120A8607C518
title: "Add Remove Footer View"
domain: adtoolkit://cookbook/ui/settings/views/add-remove-footer-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A small plus and minus button bar for a list or table, with room for extra accessory controls."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - footer
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/editable-table-card
references: []
approved-by: ""
approved-date: ""
---

# Add Remove Footer View

## Overview

The add-remove footer is a compact horizontal bar with an add button and a remove button at the leading edge and free space at the trailing edge. The remove button starts disabled and is enabled by its owner when something is selected. Callers may insert extra accessory controls after the two buttons. It exists so a list or table view that is generic over its content can offer add and remove without being a button target itself.

## Behavioral Requirements

- **add-reports-through-callback**: Pressing add MUST invoke the add callback.
- **remove-reports-through-callback**: Pressing remove MUST invoke the remove callback.
- **remove-starts-disabled**: The remove button MUST be disabled when the footer is created.
- **remove-enablement-is-settable**: The footer MUST expose a flag the owner sets to enable or disable the remove button.
- **add-is-always-enabled**: The add button MUST NOT be disabled by the footer itself.
- **buttons-are-described**: The add and remove buttons MUST carry the accessibility descriptions Add and Remove.
- **accessory-insertion-order**: Accessory controls MUST be placed after the remove button, before the trailing free space, in the order they were added.
- **trailing-view-takes-slack**: A trailing view at the right edge MUST take any spare width.
- **identifiers-from-prefix**: When built with an accessibility prefix, the buttons MUST carry the identifiers prefix.add and prefix.remove.
- **spacing-from-layout**: Insets MUST come from the settings layout's row-spacing value and the gap between controls MUST be small and fixed.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Height of the buttons; width grows with accessories.

## States

| State | Appearance change |
|-------|------------------|
| Default | Add enabled, remove disabled. |
| Pressed | Standard pressed look of a small square button. |
| Disabled | Remove is dimmed while its flag is off. |
| Focused | Buttons take part in keyboard focus like any button. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: Both controls are buttons.
- **Accessibility exposure**: Each button is exposed with its description.
- **Label requirements**: Add and Remove descriptions MUST be present.
- **Announce state changes**: The disabled state of remove is exposed through the standard enabled trait.
- **Minimum tap target**: Small square buttons; the owner SHOULD keep the bar large enough for the platform's minimum target.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| add-remove-footer-view-001 | remove-starts-disabled | Create a footer | Remove is disabled and add is enabled |
| add-remove-footer-view-002 | add-reports-through-callback | Set the add callback and press add | The callback fires once |
| add-remove-footer-view-003 | remove-reports-through-callback | Enable remove, set the callback and press remove | The callback fires once |
| add-remove-footer-view-004 | remove-enablement-is-settable | Set the enablement flag on, then off | Remove follows the flag |
| add-remove-footer-view-005 | accessory-insertion-order | Add accessories A then B | Order is add, remove, A, B, then the trailing view |
| add-remove-footer-view-006 | identifiers-from-prefix | Create with prefix items | The buttons carry items.add and items.remove |
| add-remove-footer-view-007 | buttons-are-described | Read the buttons' accessibility descriptions | Add and Remove |
| add-remove-footer-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty prefix produces identifiers that start with a dot; callers SHOULD pass a real prefix or none.
- **Boundary values**: Many accessories simply extend the bar; the footer defines no wrapping.
- **Concurrent access**: Main thread only.
- **Error states**: A press with no callback assigned does nothing.
- **Offline/disconnected state**: Not applicable.

## Configuration

Options: an accessibility prefix at construction, the two callbacks, the remove enablement flag, and accessory controls added after construction.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

The Add and Remove descriptions are fixed English strings and are not localizable today (see Design Decisions).

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

- **SwiftUI**: An `HStack` with two `Button`s using `Image(systemName: "plus")` and `"minus"`, `.disabled(!canRemove)`, and a trailing `Spacer`.
- **Compose**: A `Row` of two `IconButton`s with `Icons.Default.Add` and `Remove` and `enabled = canRemove`, plus `Spacer(Modifier.weight(1f))`.
- **React/Web**: A `<div role="toolbar">` with two `<button aria-label>` elements and a flexible spacer; `disabled` follows the flag.
- **AppKit / UIKit (source)**: `ComposableSettings.AddRemoveFooterView` is an `@MainActor` `NSView` built on a horizontal `NSStackView` of spacing 4 and insets from `SettingsLayout.default[.rowSpacing]`. `addButton` and `removeButton` are small-square bezel buttons with the SF symbols plus and minus and descriptions Add and Remove; `onAdd` and `onRemove` are closures; `isRemoveEnabled` drives `removeButton`. `trailingView` takes the slack and `addAccessoryView` inserts before it. `init(accessibilityPrefix:)` sets the identifiers. It exists because a generic view controller cannot be an `NSButton` target.
- **WinUI 3**: A horizontal `StackPanel` with two `Button`s using `SymbolIcon` Add and Remove, `IsEnabled` bound to the flag, and `AutomationProperties.Name` set.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/AddRemoveFooterView.swift` |

## Design Decisions

**Decision**: The Add and Remove descriptions are hardcoded English.
**Rationale**: Closing the gap needs string keys the caller can override, which no caller has asked for yet.
**Approved**: pending

**Decision**: The footer has no tests of its own; it is exercised through the table card's footer tests.
**Rationale**: Writing a dedicated suite would duplicate those; recorded as a coverage gap.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the footer owns two buttons and their callbacks and knows nothing about the list it serves. Unit-test-coverage is partial: no suite is dedicated to `AddRemoveFooterView`; `EditableTableCardFooterTests.swift` and the card tests exercise placement, accessory order, the remove veto and hiding, but not identifiers or descriptions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
