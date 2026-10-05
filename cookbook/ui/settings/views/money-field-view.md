---
id: 00136AA1-B327-4765-932A-F11AF12F09C9
title: "Money Field View"
domain: adtoolkit://cookbook/ui/settings/views/money-field-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A labelled text row for an amount of money stored as integer cents, typed and shown through a caller-supplied formatter."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - money
  - form
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/contact-fields-view
references: []
approved-by: ""
approved-date: ""
---

# Money Field View

## Overview

The money field is a labelled text row for an amount stored as integer cents. The text is typed and shown through a formatter the caller supplies, asked for afresh on every read so a currency that changes while the pane is open re-renders in the new format. Text that does not parse, or parses outside the allowed range, is refused: nothing is written and the row shows the stored amount again. When blanks are allowed, an empty field writes nothing-as-an-amount (use the fallback) and a placeholder shows what that fallback is.

## Behavioral Requirements

- **parses-an-amount-in-range**: Text that the formatter parses to an amount inside the allowed range MUST be accepted and written as cents.
- **trims-whitespace**: Surrounding whitespace MUST be ignored when parsing.
- **refuses-unparseable-text**: Text the formatter cannot parse MUST be refused by not writing it.
- **refuses-out-of-range**: An amount outside the allowed range MUST be refused by not writing it.
- **blank-means-fallback-when-allowed**: An empty or whitespace-only field MUST write no amount when blanks are allowed, and MUST be refused otherwise.
- **refused-text-reverts**: After a refusal the row MUST show the stored amount again.
- **shows-the-stored-amount**: The field MUST show the stored amount through the formatter, or be empty when there is none.
- **formatter-is-asked-each-time**: The formatter MUST be asked afresh for every read and parse, so a changed currency re-renders without rebuilding the row.
- **placeholder-shows-the-fallback**: When a placeholder amount is set, an empty field MUST show it formatted as the placeholder; when unset, no placeholder.
- **refresh-spares-editing**: Refreshing MUST re-read the stored amount and the placeholder without disturbing a field being typed in.
- **revert-discards-editing**: Reverting MUST re-read the stored amount and the placeholder, discarding an edit in progress.
- **exposes-explanation**: The row MUST expose the caller's explanation so its group can draw it under the row.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: One standard text row.

## States

| State | Appearance change |
|-------|------------------|
| Default | Title with the formatted amount. |
| Pressed | Not applicable. |
| Disabled | Not applicable: no disabled state is defined. |
| Focused | Standard text focus. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: A labelled text field.
- **Accessibility exposure**: The field is exposed with the row's title.
- **Label requirements**: The title MUST be non-empty.
- **Announce state changes**: A refusal that reverts the text is not announced separately.
- **Minimum tap target**: Standard text field height.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-field-view-001 | parses-an-amount-in-range | Parse 150 with range 0 to 100000 cents in US dollars | 15000 cents |
| money-field-view-002 | trims-whitespace | Parse ' 1.5 ' | 150 cents |
| money-field-view-003 | refuses-unparseable-text | Parse abc | Refused |
| money-field-view-004 | refuses-out-of-range | Parse 5000 with range 0 to 100000 cents | Refused |
| money-field-view-005 | blank-means-fallback-when-allowed | Parse whitespace with blanks allowed, then a blank without | An accepted blank, then a refusal |
| money-field-view-006 | shows-the-stored-amount | Store 12000 cents and build the row | The field shows the formatted amount |
| money-field-view-007 | placeholder-shows-the-fallback | Set a placeholder of 9000 cents and clear the stored value then refresh | The field is empty and its placeholder is the formatted fallback |
| money-field-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: Empty text is a blank: accepted as no amount when allowed, refused otherwise.
- **Boundary values**: Both ends of the range are accepted.
- **Concurrent access**: Main thread only.
- **Error states**: Unparseable and out-of-range text are refused silently by reverting; no message is shown.
- **Offline/disconnected state**: Not applicable.
- **Currency change**: Asking the formatter afresh re-renders the amount when the row refreshes.

## Configuration

Options: the title, the accepted range in cents, whether blanks are allowed, the formatter provider, the getter and setter of the stored amount, an optional explanation, and a placeholder amount.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

Number and currency formatting come from the caller's formatter and its locale; the row defines no strings of its own.

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

- **SwiftUI**: A `TextField` with a `FormatStyle.Currency` binding and validation on commit; a refusal resets the bound text.
- **Compose**: An `OutlinedTextField` with a `VisualTransformation` or parse-on-blur against a `NumberFormat.getCurrencyInstance`, resetting on refusal.
- **React/Web**: An `<input inputmode="decimal">` parsed with `Intl.NumberFormat` on blur; on refusal reset the value, and set `placeholder` for the fallback.
- **AppKit / UIKit (source)**: `ComposableSettings.MoneyFieldView` is an `@MainActor` `NSView` wrapping a `TextEditView` driven by a `ViewModel<String>` whose getter formats through `formatter().editableString(cents:)` and whose setter calls the static `parse(_:formatter:range:allowsBlank:)` and writes only an accepted result. `parse` returns a double optional: nil for refusal, `.some(nil)` for an accepted blank. `refresh()` and `revert()` re-read the value and update the placeholder. It conforms to `ExplainedSettingsView`; `init(frame:)` and `init(coder:)` trap.
- **WinUI 3**: A `TextBox` with a converter based on `Windows.Globalization.NumberFormatting.CurrencyFormatter`, validating on `LostFocus` and restoring the stored text on failure; `PlaceholderText` carries the fallback.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/MoneyFieldView.swift` |

## Design Decisions

**Decision**: A refused entry is reverted silently, with no message.
**Rationale**: Matches the other settings rows; surfacing a reason would need an error channel on the row.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: parsing, formatting and storage are injected, so the row only lays out a text field and applies the parse result. Unit-test-coverage is partial: `MoneyFieldViewTests.swift` covers parsing, blanks and the stored amount with its placeholder; the revert after a refusal and a currency change are not tested.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
