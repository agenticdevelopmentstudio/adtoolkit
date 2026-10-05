---
id: 6F98F569-B8C7-4FD9-BCDD-EA9768666A16
title: "Contact Fields View"
domain: adtoolkit://cookbook/ui/settings/views/contact-fields-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A themed card of name, email, phone and website fields bound to one contact record that reports the whole record on every edit."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - contact
  - form
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/setting-observing
references: []
approved-by: ""
approved-date: ""
---

# Contact Fields View

## Overview

The contact fields view is a titled card with four text rows for a contact name, an email address, a phone number and a website. It owns one contact record. Every edit the user makes rewrites that record and reports the whole thing, so the caller stores one value rather than reassembling four. Loading a record into the view is not an edit and reports nothing. None of the fields is validated, because a half-typed value is a normal state.

## Behavioral Requirements

- **starts-empty**: A new view MUST hold an empty record and show empty fields.
- **shows-every-field**: Assigning a record MUST show all four values in their fields.
- **load-is-not-a-change**: Assigning a record MUST NOT invoke the change callback.
- **edit-reports-whole-record**: An edit made in a field MUST update the held record and invoke the change callback once with the whole record.
- **no-validation**: The view MUST accept any text in every field, including partial or malformed values.
- **reload-spares-the-field-being-edited**: Assigning a record MUST leave a field the user is currently typing in untouched; the typed text is written into the record when the edit ends.
- **load-is-immediate**: Assigning a record MUST update the fields at once and not on a later turn.
- **revert-restores-refused-fields**: After a save is refused, reverting MUST show the stored value again in each field whose attempted value differs from it, even if that field is being edited, and MUST discard that edit.
- **revert-spares-other-fields-being-edited**: Reverting MUST treat fields whose attempted value was not refused as an ordinary load, leaving a field the user has since started editing alone.
- **fields-carry-identifiers**: Each field MUST carry an identifier made of the caller's prefix and name, email, phone or url.
- **title-is-configurable**: The card's header MUST default to Contact and MAY be set by the caller.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Four standard rows under a header; width from the container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Four rows showing the record. |
| Pressed | Not applicable: the card is not itself pressable. |
| Disabled | Not applicable: the card defines no disabled state. |
| Focused | The focused row shows the standard text focus; the rest are unchanged. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: Each row is a text field.
- **Accessibility exposure**: Each field is exposed with its row title and its identifier.
- **Label requirements**: Rows are titled Name, Email, Phone and Website.
- **Announce state changes**: Not applicable beyond text-field defaults.
- **Minimum tap target**: Rows use standard text field height.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| contact-fields-view-001 | starts-empty | Create the view | The record equals an empty record and the name field is empty |
| contact-fields-view-002 | shows-every-field | Assign a full record | All four fields show their values |
| contact-fields-view-003 | load-is-not-a-change | Set a change callback and assign a record | The callback is never invoked |
| contact-fields-view-004 | edit-reports-whole-record | Type an email into the email field | The callback fires once with the whole record, including the unchanged name |
| contact-fields-view-005 | fields-carry-identifiers | Create with prefix client.contact | Identifiers are client.contact.name, .email, .phone and .url |
| contact-fields-view-006 | shows-every-field | Assign a record then read it back | The record round-trips unchanged |
| contact-fields-view-007 | reload-spares-the-field-being-edited | Focus the email field, type, then assign a record with a different name | The name updates and the email keeps the typed text |
| contact-fields-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: All fields default to empty and empty is valid.
- **Boundary values**: No length limits are applied.
- **Concurrent access**: Main thread only.
- **Error states**: A refused save is handled by reverting, which restores stored values.
- **Offline/disconnected state**: Not applicable.
- **Loading a different record while editing**: The caller MUST end editing first, or the pending edit lands in the new record.

## Configuration

Options: the header title (default Contact) and the accessibility prefix; the record is assigned at runtime and a change callback is set by the caller.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

The default header and the row titles Name, Email, Phone and Website are fixed English strings and are not localizable today (see Design Decisions).

## Accessibility Options

Not applicable: the component applies no animation, color-coded meaning or custom contrast handling of its own, so Reduce Motion, Increase Contrast and Differentiate Without Color need no handling here.

## Feature Flags

Not applicable: no feature-flag check applies; the component behaves the same unconditionally.

## Analytics

Not applicable: the component emits no analytics, tracking or telemetry.

## Privacy

The view holds contact details only in memory for as long as it exists and stores or transmits nothing; the caller decides where the record goes.

## Logging

Not applicable: the component performs no logging of its own.

## Platform Notes

- **SwiftUI**: A `Form` section of four `TextField`s bound to a `@Binding<ContactDetails>`; use `.onSubmit` or focus loss to report.
- **Compose**: A `Column` of four `OutlinedTextField`s with state hoisted to a `ContactDetails` value and an `onChange` lambda.
- **React/Web**: A `<fieldset>` of four labelled `<input>`s (`type=email`, `tel`, `url` where wanted) controlled by one record in state.
- **AppKit / UIKit (source)**: `ComposableSettings.ContactDetails` is a `Codable`, `Equatable`, `Sendable` struct of four strings. `ContactFieldsView` is an `@MainActor` `GroupView` subclass whose four rows are `TextEditView`s bound to a `ViewModel` of getter and setter closures. An `isLoading` flag suppresses reporting while `details` is assigned; `applyToFields` writes straight to the text fields and skips one with a live field editor; `revert(attempted:stored:)` uses `FieldSync.force` for refused fields. It calls the designated `GroupView.init(withHeaderView:)` because a subclass cannot chain to the convenience initializer.
- **WinUI 3**: A `StackPanel` of four `TextBox`es with `Header` set, a `ContactDetails` record updated on `LostFocus`, and an `isLoading` guard around programmatic assignment.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/ContactFieldsView.swift` |

## Design Decisions

**Decision**: Row titles and the default header are hardcoded English.
**Rationale**: The view is used by one host today; closing the gap needs string keys.
**Approved**: pending

**Decision**: No field is validated.
**Rationale**: A half-typed phone number is normal and a client with no email is normal; validation is left to whoever consumes the record.
**Approved**: pending

**Decision**: Loading a different record while a field is being edited requires the caller to end editing first.
**Rationale**: The view cannot tell a reload of the same record from a different one; making it safe would need a record identity the type does not carry.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the view only binds four fields to one record and reports it, leaving storage and validation to the caller. Unit-test-coverage is partial: `ContactFieldsViewTests.swift` covers the empty start, loading, no report on load, whole-record reporting, identifiers, round trip and keeping the field being edited; `revert(attempted:stored:)` has no test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
