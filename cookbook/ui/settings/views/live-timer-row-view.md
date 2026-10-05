---
id: 4BB40927-776A-41D6-86C9-962CCC1E43BC
title: "Live Timer Row View"
domain: adtoolkit://cookbook/ui/settings/views/live-timer-row-view
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One running timer: an origin dot, title, optional subtitle, a ticking clock and a stop button, plus the ticker that drives clocks."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - timer
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/live-timer-list-view
references: []
approved-by: ""
approved-date: ""
---

# Live Timer Row View

## Overview

The live timer row shows one running timer: a dot saying whether it was started by hand or automatically, a title, an optional smaller subtitle, an elapsed clock and a stop button. It knows nothing about billing; the caller writes whatever it wants into the title and subtitle. A separate ticker object schedules one repeating tick for a whole list of rows so the rows stay a rendering concern.

## Behavioral Requirements

- **shows-title-and-subtitle**: The row MUST show the model's title and subtitle.
- **hides-empty-subtitle**: The subtitle line MUST be hidden when the subtitle is absent or empty.
- **elapsed-is-a-clock**: The elapsed time MUST be shown as a clock of hours, minutes and seconds counted from the model's start time.
- **elapsed-never-negative**: If the injected clock is earlier than the start time, the row MUST show zero elapsed, never a negative time.
- **clock-is-injectable**: The row MUST take its notion of now from an injectable clock so tests can state the time.
- **clock-uses-fixed-width-digits**: The clock MUST use a monospaced style so the row does not shift sideways as the seconds roll over.
- **update-swaps-the-model**: Updating MUST replace the shown model and recompute the clock from the new start time.
- **stop-reports-the-id**: Pressing stop MUST report the model's id through the stop callback.
- **origin-dot-shows-origin**: The origin dot MUST be filled for a hand-started run and hollow for an automatic one.
- **origin-tooltips-are-the-callers**: The tooltips for the two origins MUST default to Started by hand and Started automatically and MUST be settable, taking effect on the shown row at once.
- **title-gives-way-to-clock**: When space is short the title and subtitle MUST truncate before the clock and stop button do.
- **controls-carry-identifiers**: The stop button and the clock MUST carry identifiers built from the model's id.
- **ticker-ticks-while-started**: A ticker MUST call its tick callback once per interval from start until stop.
- **ticker-start-is-idempotent**: Starting a running ticker MUST change nothing and MUST NOT double its rate.
- **ticker-stop-is-safe**: Stopping a ticker that is not running MUST be harmless.
- **ticker-runs-during-tracking**: The ticker MUST keep ticking while a menu is open or a list is scrolling.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: None of its own.
- **Padding**: None of its own; the container supplies spacing.
- **Font**: From the theme's text roles.
- **Background**: None; transparent over its container.
- **Foreground/Text**: From the theme's text roles.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: One line, or two when a subtitle shows; the clock and stop button never shrink.

## States

| State | Appearance change |
|-------|------------------|
| Default | Dot, text, clock and stop button in a row. |
| Pressed | Stop shows the standard pressed look. |
| Disabled | Not applicable: the stop button is hidden by the list for automatic timers rather than disabled. |
| Focused | The stop button takes part in keyboard focus. |
| Loading | Not applicable. |

## Accessibility

- **Role/trait**: The stop control is a button; the clock is static text.
- **Accessibility exposure**: The stop button is described as Stop timer; the clock and stop carry identifiers.
- **Label requirements**: The stop description MUST be present.
- **Announce state changes**: The clock is not announced each second; assistive technology reads it on demand.
- **Minimum tap target**: The stop button is a small accessory-bar button.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| live-timer-row-view-001 | shows-title-and-subtitle | Build with title Acme and a subtitle | Both lines show and the subtitle is visible |
| live-timer-row-view-002 | hides-empty-subtitle | Build with no subtitle | The subtitle line is hidden |
| live-timer-row-view-003 | elapsed-is-a-clock | Start 1 hour 5 minutes 3 seconds before now | The clock reads 1:05:03 |
| live-timer-row-view-004 | elapsed-never-negative | Set the clock earlier than the start | The clock reads 0:00:00 |
| live-timer-row-view-005 | update-swaps-the-model | Update with a new id, title and start 5 minutes ago | The title changes, the clock reads 0:05:00 and the id changes |
| live-timer-row-view-006 | stop-reports-the-id | Press stop | The callback receives the model's id |
| live-timer-row-view-007 | controls-carry-identifiers | Read the stop and clock identifiers for run-1 | timer.run-1.stop and timer.run-1.elapsed |
| live-timer-row-view-008 | origin-tooltips-are-the-callers | Set a custom automatic tooltip | The dot's tooltip changes immediately |
| live-timer-row-view-009 | ticker-ticks-while-started | Start a ticker and deliver two ticks, stop, deliver another | Two ticks arrive and none after stop |
| live-timer-row-view-010 | ticker-start-is-idempotent | Start a ticker twice and deliver one tick | One tick arrives |
| live-timer-row-view-011 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty title shows an empty line; a nil or empty subtitle hides its line.
- **Boundary values**: A start time in the future shows zero.
- **Concurrent access**: Main thread only; the ticker delivers on the main thread.
- **Error states**: Not applicable.
- **Offline/disconnected state**: Not applicable.
- **Run-loop slack**: Ticks may land a tenth of the interval late so the system can coalesce wakeups.

## Configuration

Options: the model (id, title, optional subtitle, start time, manual flag), the injected clock, the stop callback and the two origin tooltips; the ticker takes an interval, default one second.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

The default tooltips, the stop tooltip and the Stop timer description are fixed English strings; the origin tooltips are settable, the rest are not (see Design Decisions).

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

- **SwiftUI**: A `TimelineView(.periodic(from:by:1))` supplies the tick; format with `Text(timerInterval:)` or a duration formatter.
- **Compose**: A `LaunchedEffect` loop with `delay(1000)` updating a `produceState` clock; the row is a `Row` with a weighted, ellipsizing `Column`.
- **React/Web**: A `setInterval` hook (clear on unmount) and `font-variant-numeric: tabular-nums`; the title uses `text-overflow: ellipsis`.
- **AppKit / UIKit (source)**: `ComposableSettings.LiveTimerRowView` is an `@MainActor` `NSView` with a nested `Model` (`Equatable`, `Sendable`), `ThemedLabel`s for origin, title, subtitle and elapsed (the `.code` text role), and an `NSButton` stop control with the `stop.fill` symbol. Title and subtitle compression resistance is 499, below the labels' hugging. The clock uses `DurationFormatter.clock(seconds:)`. `LiveTimerTicker` is an `@MainActor` class using a `Timer` added to `RunLoop.main` in `.common` mode with tolerance one tenth of the interval; `fireForTests()` delivers one tick synchronously.
- **WinUI 3**: A grid with `TextBlock`s and a `Button` with a `SymbolIcon`; drive the clock with a `DispatcherTimer` and truncate with `TextTrimming="CharacterEllipsis"`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/LiveTimerRowView.swift` |

## Design Decisions

**Decision**: The stop tooltip, the Stop timer description and the default origin tooltips are hardcoded English.
**Rationale**: Only the origin tooltips are overridable today because that vocabulary is the caller's; the rest have no override.
**Approved**: pending

**Decision**: The ticker is declared in the same file as the row.
**Rationale**: They are small and used together; splitting the ticker out would be a mechanical move if it gains another consumer.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Separation-of-concerns is passed: the row only renders a model and reports stop, the clock is injected and scheduling lives in the separate ticker. Unit-test-coverage is passed: `LiveTimerRowViewTests.swift` covers title and subtitle, hidden subtitle, the clock, a backwards clock, update, stop, identifiers, ticker delivery and idempotent start, and origin tooltips.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
