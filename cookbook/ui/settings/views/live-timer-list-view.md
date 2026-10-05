---
id: F012373C-0094-46E8-9D40-B2A65A96C8B5
title: "Live Timer List View"
domain: adtoolkit://cookbook/ui/settings/views/live-timer-list-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A list of live timer rows whose clocks move once a second only while the list can be seen, with a message when nothing runs."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - timer
  - list
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/live-timer-row-view
references: []
approved-by: ""
approved-date: ""
---

# Live Timer List View

## Overview

The live timer list shows one row per running timer and a line of text when none is running. Rows are kept by id when the timers change, so a timer that is still running keeps its row and its clock never jumps; rows are rebuilt only when timers start or stop. Only a hand-started timer shows a stop button. The list owns a ticker and runs it only while it can be seen: in a window that is on screen and not covered, with something running. When it becomes visible again the clocks catch up at once.

## Behavioral Requirements

- **shows-empty-message**: The empty message MUST be visible when no timers are set and hidden otherwise.
- **one-row-per-timer**: The list MUST show one row per timer, in the given order.
- **keeps-rows-by-id**: A reload MUST keep the row of every timer still listed and update it rather than rebuild it.
- **updates-in-place-when-ids-match**: When the ids are unchanged, only rows whose model changed MUST be updated.
- **only-manual-can-stop**: The stop button MUST be visible only on a hand-started timer's row.
- **stop-reports-the-id**: Stopping a row MUST report that timer's id through the list's stop callback.
- **ticks-only-while-seen**: The ticker MUST run only while at least one timer exists and the window is visible.
- **catches-up-when-seen**: When the list becomes seen, the clocks MUST be refreshed immediately and not wait for the next interval.
- **watches-occlusion**: The list MUST re-evaluate visibility when its window's occlusion changes, as well as when it moves into a window.
- **no-window-means-not-seen**: With no window the list MUST treat itself as not seen.
- **tick-notifies-the-host**: After every tick the list MUST call the host's tick callback so other on-screen elements can count the same seconds.
- **clock-and-tooltip-propagate**: The injected clock and the automatic-origin tooltip MUST apply to existing and new rows.
- **visibility-is-injectable**: The visibility check MUST be injectable so a test can cover a window that is open but covered.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Rows stacked with a small fixed gap; width from the container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Rows stacked. |
| Pressed | Per row. |
| Disabled | Not applicable. |
| Focused | Per row. |
| Loading | Not applicable. |
| Empty | Only the secondary-text empty message shows. |

## Accessibility

- **Role/trait**: A group of rows.
- **Accessibility exposure**: Rows expose their own controls; the empty message is static text.
- **Label requirements**: The empty message MUST be non-empty.
- **Announce state changes**: Not applicable: no announcement on tick.
- **Minimum tap target**: Per row.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| live-timer-list-view-001 | shows-empty-message | Create with Nothing running. and set no timers, then set one, then none | Message visible, hidden, visible again, with zero rows at the end |
| live-timer-list-view-002 | only-manual-can-stop | Set a manual and an automatic timer | Stop buttons are visible and hidden respectively |
| live-timer-list-view-003 | keeps-rows-by-id | Set a timer, keep its row, reload with a changed subtitle | The same row object remains with the new subtitle |
| live-timer-list-view-004 | stop-reports-the-id | Set a manual timer a and press its stop | The list callback receives a |
| live-timer-list-view-005 | ticks-only-while-seen | With visibility false set a timer, then make it visible, then tick | No tick, then one immediately, then one more |
| live-timer-list-view-006 | ticks-only-while-seen | Clear all timers while visible and tick | No tick is delivered |
| live-timer-list-view-007 | no-window-means-not-seen | Ask the default visibility check with no window | False |
| live-timer-list-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: No timers shows only the empty message.
- **Boundary values**: Reordering timers rebuilds rows but keeps each by id.
- **Concurrent access**: Main thread only.
- **Error states**: Not applicable.
- **Offline/disconnected state**: Not applicable.
- **Window covered or on another Space**: The window stays open but is not seen; the list stops ticking until it is visible again.

## Configuration

Options: the empty message and the tick interval (default one second) at construction; the injected clock, the visibility check, the automatic-origin tooltip and the stop and tick callbacks afterwards.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

The empty message is supplied by the caller; the default automatic-origin tooltip is a fixed English string and is settable.

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

- **SwiftUI**: A `ForEach` over timers keyed by id inside a `TimelineView` that pauses while the scene is inactive (`scenePhase`).
- **Compose**: A `LazyColumn` with `key = { it.id }` and a tick effect gated by `LocalLifecycleOwner` resumed state.
- **React/Web**: A keyed list rendering plus a `setInterval` gated by the Page Visibility API and an `IntersectionObserver`.
- **AppKit / UIKit (source)**: `ComposableSettings.LiveTimerListView` is an `@MainActor` `NSView` holding a vertical `NSStackView` of spacing 8, an empty `ThemedLabel` and `LiveTimerRowView`s. `windowIsVisible` defaults to `window.occlusionState.contains(.visible)` and observes `NSWindow.didChangeOcclusionStateNotification` from `viewDidMoveToWindow`. `visibilityChanged()` starts or stops the owned `LiveTimerTicker` and ticks at once when seen. `setTimers(_:)` keeps rows in a dictionary keyed by id.
- **WinUI 3**: A `ListView` keyed by id with a `DispatcherTimer` started and stopped on `Window.VisibilityChanged` and `Window.Activated`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/LiveTimerListView.swift` |

## Design Decisions

**Decision**: The occlusion observer is tested only through the injected visibility check, not through real window notifications.
**Rationale**: A real occlusion change needs an on-screen window, which the unit target does not have; the injected check covers the logic.
**Approved**: pending

**Decision**: The default automatic-origin tooltip is hardcoded English.
**Rationale**: It is settable by the caller; a localization pass would supply string keys.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the list only arranges rows and decides when the ticker runs; row rendering and scheduling are in the row view and ticker. Unit-test-coverage is partial: `LiveTimerListViewTests.swift` covers the empty message, stop visibility, row reuse, stop reporting, ticking only while seen and the no-window case; the real occlusion notification is not exercised.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
