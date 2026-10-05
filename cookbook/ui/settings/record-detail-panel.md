---
id: 0B7E4C0A-3C55-4B4F-9E52-6D1A8F2C7A11
title: "Record Detail Panel"
domain: adtoolkit://cookbook/ui/settings/record-detail-panel
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The pane for one record in a record-list settings window — it holds the record, keeps the sidebar title in step, and reports each accepted edit once."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - records
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/field-sync
  - adtoolkit://cookbook/ui/settings/record-detail-window-controller
references: []
approved-by: ""
approved-date: ""
---

# Record Detail Panel

## Overview

The record detail panel is the settings pane that shows one record in a window
whose sidebar lists records. It holds the record, keeps the sidebar row's title
equal to the record's title, and reports every accepted edit through a single
save callback. It never writes the record anywhere itself, so a refused save is
handled once, by the window's owner, rather than once per field. A concrete pane
builds its cards, passes each edited record to the panel's commit operation, and
names the field that should take the cursor when the record is newly added.

## Behavioral Requirements

- **holds-the-record**: The panel MUST hold the record it was created with and
  expose it read-only to callers; only adopt and commit change it.
- **title-from-record**: The panel's sidebar title MUST equal the record's title
  when it is created.
- **commit-reports-a-real-edit**: Committing an edited record that differs from
  the held record MUST store it as the held record, update the sidebar title to
  match, and report it through the save callback exactly once.
- **commit-ignores-no-change**: Committing a record equal to the held record
  MUST NOT report anything and MUST NOT change the title, so a field that ends
  editing on the value it began with sends no write.
- **adopt-stores-without-saving**: Adopting a record MUST replace the held
  record and update the sidebar title, and MUST NOT report through the save
  callback.
- **title-set-only-when-different**: The panel MUST assign the sidebar title
  only when it differs from the record's title, so an unchanged title causes no
  sidebar update.
- **focus-name-selects-the-name-field**: Focusing the name MUST put the cursor in
  the name field with its text selected, and MUST do nothing when the pane's
  view is not yet loaded or the pane names no name field.
- **no-name-field-by-default**: A pane that does not name a name field MUST
  have none, so focusing the name is a no-op for it.
- **never-persists**: The panel MUST NOT write the record to storage or a
  service; persistence is the owner's, reached only through the save callback.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: Not applicable — the base pane draws nothing itself; the cards a concrete pane adds define appearance.
- **Padding**: Inherited from the settings pane layout.
- **Font**: Inherited from the cards the concrete pane adds.
- **Background**: Inherited from the settings pane.
- **Foreground/Text**: Inherited from the cards.
- **Border**: None of its own.
- **Shadow**: None of its own.
- **Min/Max size**: Inherited from the settings pane.

## States

| State | Appearance change |
|-------|------------------|
| Default | The pane shows the held record's fields. |
| Pressed | Not applicable: the pane is a container, not a control. |
| Disabled | Not applicable: the base pane has no disabled state; fields disable themselves. |
| Focused | Focusing the name puts the cursor in the name field with its text selected. |
| Loading | Not applicable: the record is supplied at creation. |

## Accessibility

- **Role/trait**: Inherited from the settings pane; the pane adds no role.
- **Label requirements**: The sidebar row is labeled by the record's title, kept current as it changes.
- **Announce state changes**: Not applicable — the title change is a visible sidebar update.
- **Minimum tap target**: Not applicable — the pane is not a control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| record-detail-panel-001 | title-from-record | A pane created with a record titled `Draft` | The sidebar title is `Draft` |
| record-detail-panel-002 | commit-ignores-no-change | Commit a record equal to the held one | The save callback is not called |
| record-detail-panel-003 | commit-reports-a-real-edit | Commit a record titled `Final` over one titled `Draft` | The save callback receives the `Final` record once; the held record is `Final` |
| record-detail-panel-004 | commit-reports-a-real-edit | The same commit | The sidebar title is `Final` |
| record-detail-panel-005 | adopt-stores-without-saving | Adopt a record titled `Renamed elsewhere` | The save callback is not called; the sidebar title is `Renamed elsewhere` |
| record-detail-panel-006 | focus-name-selects-the-name-field | A pane whose view is not loaded; focus the name | Nothing happens and nothing fails |
| record-detail-panel-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: A record with an empty title gives an empty sidebar title.
- **Boundary values**: Two records equal in every field are the same edit, whatever their title.
- **Concurrent access**: Not applicable — the pane is used from the main thread only.
- **Error states**: A refused save is not seen by the pane; the owner restores the fields (see field-sync).
- **Offline/disconnected state**: Not applicable.
- **Absent callback**: Committing with no save callback set updates the held record and title and reports nothing.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| record | record value | none (required) | The record the pane shows |
| icon | optional image | none (required argument, may be absent) | The sidebar row's image |
| save callback | function of record | none | Called with each accepted edit |
| name field | optional text field | none | The field focusing the name uses |

## Deep Linking

Not applicable: selection by record id is the window's concern, not the pane's.

## Localization

Not applicable: the pane defines no strings; titles come from the record.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation. |
| Increase Contrast | Inherited from the cards. |
| Differentiate Without Color | Not applicable: no color use of its own. |

## Feature Flags

Not applicable.

## Analytics

Not applicable: no events are emitted.

## Privacy

- **Data collected**: None itself; it holds the record in memory.
- **Storage**: Not applicable — it never persists the record.
- **Transmission**: Not applicable — it hands edits to the owner only.
- **Retention**: The record lives as long as the pane.

## Logging

Not applicable: the pane performs no logging.

## Platform Notes

- **SwiftUI**: Hold the record in a view model; expose one `onSave` closure and call it from a `commit` function that compares with the current value first. Title changes flow to the sidebar through the model.
- **Compose**: Keep the record in a state holder, call `onSave` from a `commit` function that returns early when the new value equals the old, and drive the list item title from the same state.
- **React/Web**: Keep the record in state; a `commit` handler returns when the edited value deep-equals the current one, otherwise sets state and calls the `onSave` prop. The list row reads the title from the same state.
- **AppKit / UIKit**: In `RecordDetailPanel.swift`, `RecordDetailPanel<Record>` is an open generic `@MainActor` subclass of `SettingsPanelViewController`, where `Record` conforms to `RecordDetailItem` and `Equatable`. `commit(_:)` guards on `!=`, calls `adopt(_:)` and then `onSave`. `adopt(_:)` sets `descriptor.title` only when different. `nameTextField` is an overridable property that defaults to nil, and `focusName()` calls `makeFirstResponder` and `selectAll`. Its designated initializer takes the record and an icon and builds a `SettingsPanelDescriptor`.
- **WinUI 3**: Implement the pane as a `UserControl` with a generic or `object` record property and an `EventHandler` or `Action<Record>` save event; `Commit` compares with `Equals` and returns early on equality, then updates the navigation item's `Content` and raises the event. `FocusName` calls `Focus` on the name `TextBox` and `SelectAll`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/RecordDetailPanel.swift` |

## Design Decisions

**Decision**: The panel reports edits through one callback and never writes the record itself.
**Rationale**: The source's doc comment says a refused save is then handled once, by the window's owner, rather than once per field; the cost is that every owner must wire the callback.
**Approved**: pending

**Decision**: Commit compares the edited record with the held one and sends nothing when they are equal.
**Rationale**: The source guards on inequality so a field that ends editing on the value it began with sends no write; this requires the record type to be comparable for equality.
**Approved**: pending

**Decision**: Adopt exists separately from commit so a refresh from storage can retitle the sidebar without reporting a save.
**Rationale**: The source documents adopt as taking current stored values without saving, called first by a subclass's apply before it refreshes its fields.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the panel holds a record, keeps a title and reports edits, and leaves persistence to the owner through the save callback. Unit-test-coverage is partial: `RecordFieldRefreshTests.swift` has `commitReportsOnlyAnEditThatChangesTheRecord` and `adoptRetitlesWithoutSaving`, which cover commit and adopt, but `focusName` and the default absent name field have no tests.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
