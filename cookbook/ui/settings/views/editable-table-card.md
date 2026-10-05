---
id: 9016CB03-9682-404F-B787-C271039F25B3
title: "Editable Table Card"
domain: adtoolkit://cookbook/ui/settings/views/editable-table-card
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A themed card holding a sortable, in-place-editable table with typed cells and an add and remove footer."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - table
  - editing
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/add-remove-footer-view
  - adtoolkit://cookbook/ui/settings/views/money-field-view
references: []
approved-by: ""
approved-date: ""
---

# Editable Table Card

## Overview

The editable table card is a themed card holding a table. Columns are declared with a title, width and kind: editable or read-only text, a toggle, an on/off indicator, a day, a time of day, a duration or a money amount. Rows carry an id, one value per column, a flag that marks them visually and a read-only flag. Headers of sortable columns report clicks instead of reordering, so the owner decides the order. Cells edit in place; typed cells parse their text and report a typed value or reject it. A footer offers add and remove and may hold extra controls. A reload that arrives while a cell is being edited is held until the edit ends.

## Behavioral Requirements

- **columns-in-declared-order**: The table MUST show one column per declared column, in declared order, with the declared titles and widths.
- **sort-reports-only**: Only sortable columns MUST carry sorting; clicking one MUST report the column id and direction and MUST NOT reorder rows, which stay in the order given.
- **rows-in-given-order**: The table MUST show one row per given row, in order.
- **empty-message**: An empty table MUST hide its header and show the empty message; a non-empty table MUST hide the message.
- **visible-row-count**: The table MUST size itself to show a configurable number of rows, six by default.
- **toggle-cells-report**: A toggle cell MUST show its state as a switch and report the row id, the column id and the new state when changed.
- **indicator-cells**: An indicator cell MUST show a filled mark for on and a hollow mark for off, with an accessibility label of its title followed by on or off.
- **mismatched-cell-draws-nothing**: A cell whose value does not match its column's kind MUST draw nothing.
- **text-edit-reports-new-text**: Committing an edit to an editable text cell MUST report the row id, column id and new text.
- **unchanged-edit-is-not-reported**: Ending an edit whose text equals the text the cell was filled with MUST report nothing.
- **edit-binds-to-its-row-and-column**: An edit MUST be committed against the row and column the field was filled for, not the row or column now at that position, so reloads, sorting by the owner and header drags cannot move an edit to another record.
- **gone-or-unknown-edits-are-dropped**: An edit whose row no longer exists, or whose field the table cannot place, MUST NOT be reported.
- **typed-day**: A day cell MUST accept only a strict year-month-day text in the card's time zone and report a day.
- **typed-time**: A time cell MUST parse local time text, place it nearest the cell's reference date, and report a time.
- **typed-duration**: A duration cell MUST parse its text with the duration formatter, check the declared range, and report whole seconds or minutes as declared.
- **typed-money**: A money cell MUST parse its text with the money formatter in the cell's currency (US dollars by default), check the declared range, and report cents; a blank MUST report no amount when blanks are allowed.
- **unparseable-edit-is-rejected**: Text that does not parse, or parses out of range, MUST be reported through the rejected-edit callback with the row and column and MUST NOT be reported as an edit.
- **read-only-rows-reject-edits**: A read-only row MUST reject every edit through the rejected-edit callback and show its stored values again.
- **reload-held-while-editing**: A reload that arrives while a cell is being edited MUST be held until the edit commits or the window closes, and a later reload MUST fold into the held one.
- **close-releases-held-reload**: Closing the window while a reload is held MUST end the edit and apply the held reload.
- **update-rows-in-place**: Updating rows by id MUST replace only the named rows, keep order and selection, and report false for an id the table does not have.
- **selection-by-id**: The table MUST select by row id, report false for a missing id and leave the selection alone, restore selection by id after a reload, and clear it when its row goes away.
- **selection-reports-are-deduplicated**: The selection callback MUST report each change once, including losing the selection.
- **remove-follows-selection**: Add MUST always be enabled; remove MUST be enabled only while a row is selected and the owner's can-remove check allows it.
- **footer-can-be-hidden**: The add and remove footer MUST be hideable.
- **footer-accessories**: Callers MUST be able to add footer buttons and a pull-down menu button whose items are rebuilt each time it opens.
- **flagged-rows-are-marked**: A flagged row MUST be marked visibly without using the selection color.
- **locale-and-zone-reload**: Changing the time zone or locale MUST reload the table so day, time and money cells re-render.
- **views-are-recycled**: Row views and cells MUST be recycled while scrolling.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: Inherited from the card.
- **Padding**: From the settings layout tokens.
- **Font**: Cells use the theme's body text role.
- **Background**: The card background; a flagged row adds a warning wash at low opacity over it, distinct from the selection color.
- **Foreground/Text**: From the theme's text roles.
- **Border**: The card's own.
- **Shadow**: None added.
- **Min/Max size**: Height from the visible-row count; width from the container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Header and rows. |
| Empty | Header hidden, empty message shown. |
| Selected | The row has the selection highlight; remove is enabled. |
| Flagged | A warning wash over the row background. |
| Editing | One cell shows a live text field; reloads are held. |
| Read-only row | Edits are rejected and the row snaps back. |
| Disabled | Not applicable: the card defines no disabled state. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: A table with cells; toggles are switches.
- **Accessibility exposure**: Indicator cells expose their title with on or off; footer buttons are described Add and Remove.
- **Label requirements**: Columns MUST have titles.
- **Announce state changes**: Selection and toggle changes use the standard table and switch semantics.
- **Minimum tap target**: Rows use the table's standard row height.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editable-table-card-001 | columns-in-declared-order | Declare path, rate and on columns | Three columns in that order with their titles |
| editable-table-card-002 | sort-reports-only | Click a sortable header | The sort callback receives the column id and direction and rows keep their order |
| editable-table-card-003 | empty-message | Set no rows, then rows | Message and hidden header, then the reverse |
| editable-table-card-004 | toggle-cells-report | Flip a toggle cell in row r2 | The callback receives r2, the column id and the new state |
| editable-table-card-005 | text-edit-reports-new-text | Commit the text $150 in the rate column of r1 | The edit callback receives r1, rate and $150 |
| editable-table-card-006 | unchanged-edit-is-not-reported | End an edit without changing the text | Nothing is reported |
| editable-table-card-007 | edit-binds-to-its-row-and-column | Type, then reload so the row moves, then commit | The edit is reported against the original row |
| editable-table-card-008 | edit-binds-to-its-row-and-column | Drag a column header and commit an edit | The edit is reported under the column it was typed into |
| editable-table-card-009 | gone-or-unknown-edits-are-dropped | Delete the row under a live field and commit | Nothing is reported |
| editable-table-card-010 | reload-held-while-editing | Begin editing, reload with other rows, then commit | The old rows stay until the commit, then the reload shows |
| editable-table-card-011 | close-releases-held-reload | Hold a reload and close the window | The held reload is applied |
| editable-table-card-012 | typed-day | Edit the day, start, hours and rate cells with valid text | Typed values for each are reported and none rejected |
| editable-table-card-013 | unparseable-edit-is-rejected | Enter text that is not a day, hours or amount | Each is rejected and none reported |
| editable-table-card-014 | typed-money | Blank a money cell that allows blanks | The edit reports no amount |
| editable-table-card-015 | read-only-rows-reject-edits | Edit any cell of a read-only row | The edit is rejected and nothing is reported as an edit |
| editable-table-card-016 | update-rows-in-place | Update row b with new values | Only b changes; order and selection are kept |
| editable-table-card-017 | update-rows-in-place | Update an id the table does not have | False and no rows change |
| editable-table-card-018 | selection-by-id | Select b, then select a missing id | True then false, selection stays on b |
| editable-table-card-019 | remove-follows-selection | Create the card, then select a row | Add enabled with remove disabled, then remove enabled |
| editable-table-card-020 | selection-reports-are-deduplicated | Select r1 then clear | Reports r1 then nil |
| editable-table-card-021 | footer-accessories | Open a footer menu button | It is a pull-down whose items are rebuilt on open |
| editable-table-card-022 | flagged-rows-are-marked | Flag a row | Its row view is marked flagged |
| editable-table-card-023 | views-are-recycled | Scroll through many rows | Distinct row views are fewer than half the rows seen |
| editable-table-card-024 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: No rows shows the empty message; a blank money cell is a no-amount edit only where blanks are allowed.
- **Boundary values**: Range limits on duration and money are inclusive; the visible row count only sizes the table.
- **Concurrent access**: Main thread only; an edit and a reload arriving together are ordered by holding the reload.
- **Error states**: Unparseable, out-of-range and read-only edits go to the rejected-edit callback; no message is shown.
- **Offline/disconnected state**: Not applicable.
- **Header drag**: Edits stay with the column they were typed into after columns are reordered.
- **Mismatched cell**: A cell value of the wrong kind draws nothing instead of failing.

## Configuration

Options: the columns, rows, empty message, visible row count, time zone, locale, can-remove check, footer visibility, footer buttons, and the callbacks for add, remove, selection, edit, typed edit, rejected edit, toggle and sort.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

Day, time, duration and money cells format and parse through the card's locale and time zone; the empty message and column titles come from the caller. The footer's Add and Remove descriptions are fixed English strings (see the footer spec).

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

- **SwiftUI**: A `Table` with `TableColumn`s and per-kind cell views; editing through `TextField` with `onSubmit`, and the held-reload rule through a pending-state buffer.
- **Compose**: A `LazyColumn` or a data-grid library with cell editors; hold incoming data in a pending state while an editor has focus.
- **React/Web**: A `<table>` or ARIA grid with `contenteditable` or input cells, keyed rows, and `aria-sort` on sortable headers; hold incoming data while an input is focused.
- **AppKit / UIKit (source)**: `ComposableSettings.EditableTableCard` is an `@MainActor` `GroupView` subclass wrapping an `NSTableView`. Types: `EditableTableColumn` with `Kind` (`.text(editable:)`, `.toggle`, `.indicator`, `.day`, `.time`, `.duration(range:)`, `.money(range:allowsBlank:)`), `EditableTableCellValue`, `EditableTableEditValue`, `EditableTableRow` and `EditableTableRowView` (warning wash at alpha 0.18). Callbacks: `onAdd`, `onRemove`, `onSelectionChange`, `onEdit`, `onTypedEdit`, `onRejectedEdit`, `onToggle`, `onSort`. `setRows` is deferred through `EditDeferredValue` while a field editor is live; `EditableTableCellField.Binding` records the row and column a field was filled for. Typed parsing uses strict `yyyy-MM-dd`, `LocalTimeText`, `DurationFormatter` and `MoneyFormatter`. `addFooterButton` and `addFooterMenuButton` extend the `AddRemoveFooterView`.
- **WinUI 3**: A `DataGrid` (Community Toolkit) with `DataGridTemplateColumn`s, `BeginningEdit` and `CellEditEnded` handlers, and a pending-reload buffer while a cell is in edit mode.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/EditableTableCard.swift` |

## Design Decisions

**Decision**: Rejected edits are reported to the owner and the row snaps back, with no message shown by the card.
**Rationale**: Keeps the card free of dialogs; the owner decides whether to tell the user, at the cost of silent reversion when it does not.
**Approved**: pending

**Decision**: A reload during an edit is held and not merged field by field.
**Rationale**: Replacing the table under a live field would drop typed text; holding is simple and safe, at the cost of stale data on screen until the edit ends.
**Approved**: pending

**Decision**: The card parses day, time, duration and money text itself.
**Rationale**: Keeps callers from repeating parsing and range checks; the cost is that the card depends on the formatters and is larger than a pure rendering view, so separation of concerns is only partial.
**Approved**: pending

**Decision**: Sorting is reported, not performed.
**Rationale**: Lets the owner sort by its own rules and keep ids stable; the card cannot show a sort indicator without the owner updating it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is partial: the card keeps storage, sorting and add/remove policy with the owner through callbacks, but it also parses typed day, time, duration and money text and manages edit deferral in one large view. Unit-test-coverage is partial: `EditableTableCardTests.swift`, `EditableTableCardTypedEditTests.swift`, `EditableTableCardUpdateTests.swift` and `EditableTableCardFooterTests.swift` cover columns, sorting, rows, toggles, edits, held reloads, binding to rows and columns, typed edits and rejections, row updates, selection, recycling and footer controls; indicator accessibility labels, the locale and time zone reload and the mismatched cell are not tested.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
