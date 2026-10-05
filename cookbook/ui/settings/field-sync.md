---
id: 76CD6DDF-9736-4478-B5A5-8E4DCB999EF9
title: "Field Sync"
domain: adtoolkit://cookbook/ui/settings/field-sync
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One policy for putting stored values back into editable fields — a refresh that never overwrites what the user is typing, and a forced revert that does."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - forms
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/record-detail-panel
references: []
approved-by: ""
approved-date: ""
---

# Field Sync

## Overview

Field sync is the single policy a record pane follows when it puts stored
values back into its editable fields, for every pane that shows a record
which can change underneath it. It has two modes. A refresh (`load`) shows
the stored value unless the user is in the middle of editing that field, so a
background poll that lands mid-word never replaces what is being typed. A
forced revert (`force`) is used after a save that was refused: the text in the
field is exactly what failed, so it is discarded, including any edit session
in progress, so that ending the edit later cannot send the refused text again.
It also provides one helper that selects a pop-up item by the value it
represents rather than by its title.

## Behavioral Requirements

- **load-skips-a-field-being-edited**: A refresh of a single-line text field
  MUST leave the field unchanged while the user is editing it.
- **load-skips-an-unchanged-field**: A refresh of a single-line text field MUST
  NOT assign the field's text when it already equals the stored value.
- **load-replaces-an-idle-field**: A refresh of a single-line text field that is
  not being edited and whose text differs MUST replace the text with the
  stored value.
- **force-discards-an-edit-in-progress**: A forced revert of a single-line text
  field MUST end the field's edit session without committing it, so that no
  later end-of-edit can send the discarded text.
- **force-replaces-a-differing-field**: A forced revert of a single-line text
  field MUST set the text to the stored value when it differs.
- **load-skips-a-focused-multiline-view**: A refresh of a multi-line text view
  MUST leave the view unchanged while it holds keyboard focus, and MUST NOT
  assign its text when it already equals the stored value.
- **force-replaces-a-multiline-view**: A forced revert of a multi-line text
  view MUST set its text to the stored value when it differs, whatever is
  being typed.
- **select-matches-by-represented-value**: Selecting a value in a pop-up
  control MUST choose the item whose represented value equals the given value,
  and MUST NOT match by item title, because two records can share a title.
- **select-with-no-match-clears-selection**: Selecting a value that no pop-up
  item represents MUST leave the control with no selected item.
- **select-skips-an-unchanged-selection**: Selecting a value MUST NOT change
  the control when the matching item is already the selected one.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: Not applicable — the component is a policy, not a view.
- **Padding**: Not applicable.
- **Font**: Not applicable.
- **Background**: Not applicable.
- **Foreground/Text**: Not applicable — it changes the text a field shows, not how it looks.
- **Border**: Not applicable.
- **Shadow**: Not applicable.
- **Min/Max size**: Not applicable.

## States

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: the component has no visual presentation of its own. |
| Pressed | Not applicable: it handles no interaction. |
| Disabled | Not applicable: it has no enabled concept. |
| Focused | A focused or in-edit field is the condition that makes a refresh a no-op (see **load-skips-a-field-being-edited**). |
| Loading | Not applicable: every operation is synchronous. |

## Accessibility

- **Role/trait**: Not applicable — the component adds no accessibility element.
- **Label requirements**: Not applicable.
- **Announce state changes**: Not applicable — it posts no announcement when it replaces a value.
- **Minimum tap target**: Not applicable — it is not a control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-sync-001 | load-replaces-an-idle-field | A field showing `old` that nobody is editing; refresh with `new` | The field shows `new` |
| field-sync-002 | load-skips-a-field-being-edited | A field showing `typing` with an edit session open; refresh with `stored` | The field still shows `typing` |
| field-sync-003 | force-discards-an-edit-in-progress | A field showing `refused` with an edit session open; forced revert with `stored` | The field shows `stored` and has no open edit session |
| field-sync-004 | select-matches-by-represented-value | A pop-up with two items both titled `Acme`, representing `c1` and `c2`; select `c2` | The second item is selected |
| field-sync-005 | select-with-no-match-clears-selection | The same pop-up; select `gone` | No item is selected |
| field-sync-006 | load-skips-a-focused-multiline-view | A multi-line view holding focus with text `draft`; refresh with `stored` | The view still shows `draft` |
| field-sync-007 | force-replaces-a-multiline-view | A multi-line view holding focus with text `draft`; forced revert with `stored` | The view shows `stored` |
| field-sync-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty stored value is an ordinary value; a refresh
  of an idle field holding text replaces it with the empty string.
- **Boundary values**: A pop-up item whose represented value is not text never
  matches, so selecting any text value leaves such an item unselected.
- **Concurrent access**: Not applicable — all operations run on the main thread
  with the controls they act on.
- **Error states**: The component has no error path; a refused save is the
  caller's concern and the forced revert is how it restores the field.
- **Offline/disconnected state**: Not applicable.
- **Multi-line force**: A forced revert of a multi-line view does not end an
  edit session explicitly; it replaces the text directly (see Design Decisions).

## Configuration

Not applicable: the component exposes no configuration; each operation takes
the control and the value to show.

## Deep Linking

Not applicable: the component has no navigable identity.

## Localization

Not applicable: the component renders no text of its own.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation. |
| Increase Contrast | Not applicable: no appearance. |
| Differentiate Without Color | Not applicable: no color use. |

## Feature Flags

Not applicable: the policy is unconditional.

## Analytics

Not applicable: no events are emitted.

## Privacy

- **Data collected**: None; it moves values between a record and a field in memory.
- **Storage**: Not applicable.
- **Transmission**: Not applicable.
- **Retention**: Not applicable — the discarded text is dropped.

## Logging

Not applicable: the component performs no logging.

## Platform Notes

- **SwiftUI**: A `TextField` bound to a model already follows one source of truth; to get the same behavior, update the bound value from the stored record only when the field does not have focus (track it with `@FocusState`), and assign unconditionally on a refused save to revert. A `Picker` selects by its `tag` value, which already matches by value rather than title.
- **Compose**: Hold the field text in `remember` state keyed by the record; on a refresh update that state only when the field is not focused (`FocusRequester` or `onFocusChanged` tracking), and on a refused save overwrite it and clear focus. A dropdown selection is stored as the value's id, not the label.
- **React/Web**: Use a controlled input; apply a refreshed value in an effect only when `document.activeElement` is not the input, and on a refused save set the value and blur the input. A `select` element matches `option` by `value` attribute, which is already by value rather than label.
- **AppKit / UIKit**: In `FieldSync.swift`, `FieldSync` is a `@MainActor` caseless enum in the `ComposableSettings` namespace with static `load`, `force` and `select` functions. For an `NSTextField`, being edited means `currentEditor()` is non-nil and the revert calls `abortEditing()`; for an `NSTextView`, focus is `window?.firstResponder === textView`. `select(_:in:)` compares each `NSMenuItem.representedObject` cast to `String` against the value and calls `selectItem(at:)`. A UIKit port would test `UITextField.isFirstResponder` and call `resignFirstResponder()` for the revert.
- **WinUI 3**: Use a `TextBox` and test `FocusState != FocusState.Unfocused` before assigning `Text` on a refresh; on a refused save assign `Text` and call `Focus(FocusState.Programmatic)` elsewhere or move focus away so the `LostFocus` handler cannot resubmit the discarded text. For a `ComboBox`, set `SelectedValuePath` and assign `SelectedValue` so the item matches by value rather than `DisplayMemberPath` text.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/FieldSync.swift` |

## Design Decisions

**Decision**: A refresh and a forced revert are separate operations rather than one operation with a flag.
**Rationale**: The source's doc comment distinguishes them by intent: `load` is for a poll that must never replace what is being typed, and `force` is for a refused save where the text in the field is exactly what failed; separate names keep a call site from choosing the wrong policy by accident.
**Approved**: pending

**Decision**: A forced revert of a text field aborts its edit session, while a forced revert of a multi-line text view only assigns its text.
**Rationale**: The source calls `abortEditing()` for the single-line field so that ending the edit later cannot send the refused text again; for the multi-line view it only replaces `string`, and no code there ends the edit, so a later end-of-edit notification would still carry whatever the view then holds, which is the stored value.
**Approved**: pending

**Decision**: Pop-up selection matches by represented value, never by title.
**Rationale**: The source's comment states that two records can share a title, and a test (`selectPicksByRepresentedValueNotTitle`) builds two items with the same title to prove the second is selectable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |

Separation-of-concerns is passed: `FieldSync` only decides whether a stored value may be written into a control and does so, with no knowledge of records, saving or views. Unit-test-coverage is partial: `RecordFieldRefreshTests.swift` covers `load` and `force` on a text field (idle, mid-edit, discarded edit) and `select` by represented value and with no match, but the multi-line text view overloads and the unchanged-value short-circuits have no tests. Data-integrity is passed because the policy exists to keep a poll from overwriting an in-progress edit and to keep a refused write from being resent.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
