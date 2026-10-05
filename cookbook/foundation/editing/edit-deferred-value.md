---
id: 267CDB61-52E4-440C-BFA2-799D8E9E12DC
title: "Edit Deferred Value"
domain: adtoolkit://cookbook/foundation/editing/edit-deferred-value
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A holder that parks a replacement value while an in-place edit is in flight and hands back only the newest one when the edit ends."
platforms:
  - swift
  - macos
tags:
  - foundation
  - editing
  - reload
  - deferral
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Edit Deferred Value

## Overview

A replacement value that must wait while an in-place edit is in flight. A table that edits its cells in place cannot swap its rows out from under a live field editor: the replacement lands before the table reloads, and the end of the edit then reads the new rows at the field's old index. So a reload that arrives mid-edit is parked here and handed back when the edit ends. It is one type rather than a flag and an optional per table, so a fix to when a held reload is released reaches every table built this way.

## Behavioral Requirements

- **initial-state**: A new holder MUST report no edit in flight and hold nothing.
- **begin-editing**: Beginning an edit MUST mark an edit as in flight; offers made from then until it ends are held.
- **offer-passes-through**: Offering a value while no edit is in flight MUST return that value immediately for the caller to apply, and MUST NOT hold it.
- **offer-while-editing-parks**: Offering a value while an edit is in flight MUST return nothing and hold the value as the pending one.
- **newest-offer-wins**: An offer made while an earlier one is still held MUST replace it; only the newest reload is worth applying.
- **end-editing-releases**: Ending the edit MUST clear the in-flight flag, return the held value if any, and leave nothing held.
- **end-editing-safe-twice**: Ending an edit when none is in flight MUST be safe and MUST return nothing; a second end after a release returns nothing.
- **state-readable**: The in-flight flag and the pending value MUST be readable, and MUST be changeable only through the operations above.
- **generic-value**: The held value MUST be generic: the holder places no requirement on what a reload is.

## Appearance

Not applicable: The holder is not a visual component.

## States

Not applicable: The holder is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The holder presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| edit-deferred-value-001 | initial-state | Create a new holder. | Not editing; nothing pending. |
| edit-deferred-value-002 | offer-passes-through | Offer `rows-1` with no edit in flight. | Returns `rows-1`; pending stays empty. |
| edit-deferred-value-003 | offer-while-editing-parks | Begin editing, then offer `rows-1`. | Returns nothing; pending is `rows-1`. |
| edit-deferred-value-004 | newest-offer-wins | Begin editing, offer `rows-1`, then offer `rows-2`. | Pending is `rows-2`. |
| edit-deferred-value-005 | end-editing-releases | Begin editing, offer `rows-2`, end editing. | Returns `rows-2`; not editing; nothing pending. |
| edit-deferred-value-006 | end-editing-safe-twice | End editing twice in a row after a held offer. | First returns the held value, second returns nothing. |
| edit-deferred-value-007 | end-editing-safe-twice | End editing on a new holder that never began. | Returns nothing; not editing. |

## Edge Cases

- **Null / empty input**: A value that is itself an empty collection is offered, held and released like any other; the holder inspects nothing.
- **Boundary values**: An offer immediately after ending an edit passes through again; an edit that begins twice without ending is still one edit, and a single end releases it.
- **Concurrent access**: The holder is a plain value with no lock; the single UI context that drives the edit also drives the holder.
- **Error states**: No operation can fail.
- **Offline / disconnected state**: Not applicable: The holder has no network access.
- **Cancellation**: Not applicable: The holder has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The holder reads no environment variable or settings key; every value arrives as a parameter.

## Deep Linking

Not applicable: The holder defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The holder contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The holder presents no UI.

## Feature Flags

Not applicable: The holder contains no feature-flag reference.

## Analytics

Not applicable: The holder contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The holder calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a generic `struct` with `private(set)` state and `mutating` operations, so a view model holds it as a stored property.
- **Compose**: A small class or data class in a view model with `isEditing` and `pending` state; with Compose lists, hold the reload in a `MutableState` and apply it on edit completion.
- **React/Web**: A closure-free class with the four methods; in React, keep it in a ref so a render during editing does not discard the parked value.
- **AppKit / UIKit**: Identical in contract to the SwiftUI note; the AppKit use is a table view whose cell field editor is active when a reload arrives, so the table owner calls begin on edit start and end on `controlTextDidEndEditing`.
- **WinUI 3**: A `struct EditDeferredValue<T>` held by the view model of a `DataGrid` or `ListView` with in-place editing: call `Begin` from `BeginningEdit`, `Offer` from the data-refresh handler, and apply the result of `End` from `CellEditEnded`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Editing/EditDeferredValue.swift` |

## Design Decisions

**Decision**: Only the newest offered reload is kept; earlier held reloads are discarded rather than queued.
**Rationale**: A reload replaces the whole data set, so applying an older one before the newer would be wasted work and could briefly show stale rows; one slot is enough.
**Approved**: pending

**Decision**: The holder does not apply the reload itself.
**Rationale**: It returns the value and leaves the apply step to the table, so the type stays free of any UI knowledge and every table keeps its own reload mechanics.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the type only decides when a reload may be applied; what a reload contains and how it is applied belong to the table. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Editing/EditDeferredValueTests.swift` covers an offer with no edit applying at once, offers during an edit with only the newest released, a second end releasing nothing, and an edit with no reload.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
