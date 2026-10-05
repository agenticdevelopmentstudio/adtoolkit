---
id: A0D31E57-2B64-4C0E-8F1B-5E7C9D4A3B22
title: "Record Detail Window Controller"
domain: adtoolkit://cookbook/ui/settings/record-detail-window-controller
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A settings window whose sidebar lists records instead of destinations, with add and remove controls, per-record panes that survive reloads, and reported selection."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - records
  - windows
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/record-detail-panel
references: []
approved-by: ""
approved-date: ""
---

# Record Detail Window Controller

## Overview

The record detail window controller is a settings window whose sidebar is a
list of records rather than a list of destinations. The sidebar is searchable,
has an add and a remove control under it, and shows a detail pane of ordinary
settings cards for the selected record. The window chrome, sidebar, search, help
drawer and navigation arrows belong to the settings window it extends; what it
adds is that the panes come and go with a model. The owner pushes the full list
of records in, the window keeps each surviving record's pane and the selection,
and reports adds, removes and selection changes back out.

## Behavioral Requirements

- **sidebar-follows-records**: Setting the records MUST show one sidebar row per
  record, in the owner's order, with the record's pane as its detail.
- **owner-order-not-alphabetical**: The sidebar MUST NOT sort rows by title,
  because records are renameable and a sorted list moves a row from under the
  cursor mid-edit.
- **pane-built-once-per-record**: The window MUST build a record's pane once,
  the first time the record is seen, and reuse that pane for every later update
  of the same record, identified by the record's own id.
- **pane-updated-every-push**: On every set of records the window MUST hand each
  pane its record's current values, then run the configure callback for it.
- **dropped-records-drop-panes**: A pane whose record is no longer in the list
  MUST be discarded.
- **selection-survives-reload**: Replacing the records MUST keep the selected
  record selected when it survives.
- **deleted-selection-takes-neighbour**: When the selected record is removed
  from the list, the window MUST select the record now at its position, or the
  last row when it was the last.
- **first-selection-is-never-blank**: When rows exist and nothing was selected,
  the window MUST select the first row so the detail pane is never blank.
- **empty-list-selects-nothing**: With no records and no fixed panels, the
  selected record MUST be absent and the empty message MUST be shown beside the
  add and remove controls when one is set.
- **empty-message-hidden-with-records**: The empty message MUST be hidden
  whenever at least one record exists.
- **add-reports-out**: Activating the add control MUST call the add callback;
  the window MUST NOT create a record itself.
- **remove-reports-selected-record**: Activating the remove control MUST call
  the remove callback with the selected record, and only when removal is allowed.
- **remove-disabled-when-nothing-selected**: The remove control MUST be disabled
  when no record is selected.
- **remove-vetoable**: When a can-remove check is set and answers false for the
  selected record, the remove control MUST be disabled and a remove MUST be
  refused even if the control is bypassed.
- **veto-change-updates-at-once**: Setting the can-remove check MUST update the
  remove control immediately.
- **remove-rechecked-every-reload**: The remove control state MUST be recomputed
  on every reload and selection change, not only when selection moves.
- **selection-reported-once**: The select callback MUST be called only when the
  selected record actually changes, so a window that reloads on a timer does not
  re-announce its selection.
- **select-by-id-ignores-unknown**: Selecting a record by an id not in the list
  MUST be ignored.
- **select-syncs-immediately**: Selecting a record MUST update the selected
  record and the remove control at once, even before the window has been shown.
- **fixed-rows-after-records**: Fixed rows MUST be listed after every record,
  MUST NOT be passed to the record callbacks, and MUST NOT be removable; while one
  is selected the selected record MUST be absent.
- **refresh-keeps-navigation-and-search**: A reload MUST keep the navigation
  trail and the sidebar search text.
- **destructive-confirm-and-failure-report-replaceable**: The window MUST offer
  a replaceable destructive confirmation and a replaceable failure report, both
  presented as sheets on the window by default.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: Inherited from the settings window.
- **Padding**: Inherited from the settings window.
- **Font**: The empty message uses the small caption text style.
- **Background**: Inherited from the settings window.
- **Foreground/Text**: The empty message uses the secondary text color.
- **Border**: Inherited from the settings window.
- **Shadow**: Inherited from the settings window.
- **Min/Max size**: Inherited from the settings window.

## States

| State | Appearance change |
|-------|------------------|
| Default | Records in the sidebar, the selected record's pane in the detail area. |
| Pressed | Not applicable: pressed states belong to the add and remove controls. |
| Disabled | The remove control is disabled when nothing is selected or removal is vetoed. |
| Focused | Inherited from the settings window. |
| Loading | Not applicable: records are pushed in by the owner. |
| Empty | The empty message shows beside the add and remove controls. |

## Accessibility

- **Role/trait**: Inherited from the settings window; the add and remove controls carry identifiers built from the accessibility prefix given at creation.
- **Label requirements**: Each sidebar row is labeled by its record's title.
- **Announce state changes**: Selection changes are visible and reported through the select callback.
- **Minimum tap target**: Inherited from the add and remove controls.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| record-detail-window-controller-001 | sidebar-follows-records | Set three records | Three rows in the owner's order |
| record-detail-window-controller-002 | first-selection-is-never-blank | Set records with nothing selected | The first record is selected |
| record-detail-window-controller-003 | pane-built-once-per-record | Push the same record twice with changed values | The pane is built once and updated twice |
| record-detail-window-controller-004 | selection-survives-reload | Select the second record, then set the records again | The second record is still selected |
| record-detail-window-controller-005 | deleted-selection-takes-neighbour | Delete the selected middle record | The record now in its position is selected |
| record-detail-window-controller-006 | empty-list-selects-nothing | Set no records | No record is selected and the empty message is shown |
| record-detail-window-controller-007 | add-reports-out | Activate add | The add callback runs once |
| record-detail-window-controller-008 | remove-vetoable | A can-remove check answering false for the selected record | The remove control is disabled and a remove is refused |
| record-detail-window-controller-009 | selection-reported-once | Select another record | The select callback runs once, and not again on an unchanged reload |
| record-detail-window-controller-010 | remove-disabled-when-nothing-selected | No selection | The remove control is disabled |
| record-detail-window-controller-011 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty record list is valid and selects nothing unless fixed rows exist.
- **Boundary values**: Deleting the last row selects the new last row.
- **Concurrent access**: Not applicable — the window is used from the main thread only.
- **Error states**: A failed change is reported through the replaceable failure report as a sheet on the window.
- **Offline/disconnected state**: Not applicable.
- **Unknown id**: Selecting an id no longer listed is ignored, so a caller can re-select after a save without checking.
- **Unshown window**: Selecting before the window is ever shown still updates the selection and remove control.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| window id | text | none (required) | The identity of the window |
| title | text | none (required) | The window title |
| accessibility prefix | text | none (required) | Prefix for the add and remove control identifiers |
| pane factory | function of record | none (required) | Builds a pane for a record seen for the first time |
| pane updater | function of pane and record | none (required) | Hands a pane its record's current values |
| empty message | optional text | none | Shown beside the controls while the list is empty |
| can-remove check | optional function of record | none (every record removable) | Vetoes removal |

## Deep Linking

Selection by record id is exposed to callers so an owner can open a window on a given record.

## Localization

The empty message is supplied by the owner, already localized. The window defines no other strings of its own.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Inherited from the settings window. |
| Increase Contrast | Inherited from the settings window and its theme. |
| Differentiate Without Color | Not applicable: no information is carried by color alone. |

## Feature Flags

Not applicable.

## Analytics

Not applicable: no events are emitted.

## Privacy

- **Data collected**: None itself; it holds the records it is given in memory.
- **Storage**: Not applicable — persistence is the owner's.
- **Transmission**: Not applicable.
- **Retention**: The records live as long as the window holds them.

## Logging

Not applicable: the window performs no logging.

## Platform Notes

- **SwiftUI**: Use a `NavigationSplitView` with a `List` of records selected by id, a toolbar or footer with add and remove buttons, and a detail view keyed by the selected id so its state survives reloads.
- **Compose**: Use a list-detail layout with a lazy list keyed by record id, and remember each record's pane state by that key so it survives list updates.
- **React/Web**: Render a sidebar list keyed by record id with a detail route, and keep per-record component state by using the id as the React key.
- **AppKit / UIKit**: In `RecordDetailWindowController.swift`, `RecordDetailWindowController<Record>` is an open generic `@MainActor` subclass of `SettingsWindow`, where `Record` conforms to `RecordDetailItem` (an `Identifiable` with a string id and a `recordTitle`). It exposes `setRecords`, `setFixedPanels`, `selectRecord(id:)`, `selectFixedPanel`, `panel(forRecordID:)`, the callbacks `onAddRecord`, `onRemoveRecord`, `onSelectRecord`, `onConfigurePanel`, the `canRemoveRecord` veto and the `footer` add and remove bar. It sets `sortsPanelsByTitle` to false and rebuilds with one `setPanels` call, reusing panel objects so the split view restores selection by identity.
- **WinUI 3**: Use a `NavigationView` or a `ListView` plus a content `Frame`, with items bound to an `ObservableCollection` keyed by record id, a footer with add and remove `Button`s, and a dictionary from id to the pane instance so panes are reused. Disable the remove `Button` through its `IsEnabled` property when nothing is selected or the veto answers false.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/RecordDetailWindowController.swift` |

## Design Decisions

**Decision**: The window never creates or deletes a record; it reports add and remove to the owner, who changes the model and pushes the list back.
**Rationale**: The source's add and remove callbacks say the owner creates the record and calls set-records, which keeps the model in one place at the cost of every owner wiring both callbacks.
**Approved**: pending

**Decision**: Panes are keyed by record id and reused across pushes, rather than rebuilt.
**Rationale**: The source comments say the split restores selection by panel identity across a rebuild, so reusing the objects is what keeps the selected row selected; ids are database ids, not row numbers, because positions change on every push.
**Approved**: pending

**Decision**: The sidebar keeps the owner's order and does not sort by title.
**Rationale**: The source sets title sorting off because rows are renameable and an alphabetical sidebar moves the row from under the cursor mid-edit; the owner sorts once, where it can also place a catch-all row last.
**Approved**: pending

**Decision**: Catch-all rows are fixed panels, never records.
**Rationale**: The source says a built-in row such as Unassigned belongs in the fixed panels, which are never removable and never passed to the record callbacks, rather than in the records.
**Approved**: pending

**Decision**: Selection is announced only on a real change, and synced directly on select rather than through the navigation notification.
**Rationale**: The source guards the select callback on a change so a timer-driven reload does not re-announce, and syncs directly because the navigation closure is wired only once the window has loaded, so an unshown window would otherwise keep a stale selection.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the window owns only list-to-pane mapping and selection, with chrome inherited from `SettingsWindow` and all model changes delegated to the owner through callbacks. Unit-test-coverage is partial: `RecordDetailWindowControllerTests.swift` has fifteen tests covering panes per record, selection, neighbour selection, the empty list, the footer, add and remove, the veto and single selection reports, but fixed panels, `onConfigurePanel` and the `confirm` and `reportFailure` defaults have no tests there.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
