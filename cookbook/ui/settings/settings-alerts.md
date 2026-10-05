---
id: 0FC99299-F3BA-4883-AB08-9BD614DA7900
title: "Settings Alerts"
domain: adtoolkit://cookbook/ui/settings/settings-alerts
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Window-attached confirmation, folder-choice and error-report sheets for settings panes, safe by default."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - alerts
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/settings-window
references: []
approved-by: ""
approved-date: ""
---

# Settings Alerts

## Overview

Settings alerts is a namespace of helpers that raise the sheets a settings pane needs: a destructive confirmation, a folder chooser and a plain error report. Each sheet attaches to a window; with no window the helpers decline safely. A confirmation can also be injected as a closure so a test can answer it without showing anything.

## Behavioral Requirements

- **confirm-declines-without-window**: A destructive confirmation requested with no window MUST log a warning and answer that the user declined.
- **confirm-shows-sheet**: With a window, a destructive confirmation MUST show a warning sheet attached to it with a destructive action button and a Cancel button, and report whether the action was chosen.
- **destructive-button-is-not-default**: The destructive button MUST NOT respond to the Return key; Return MUST press Cancel.
- **escape-cancels**: The Escape key MUST press Cancel even though the destructive button is not the default.
- **action-title-defaults-to-delete**: The destructive button's title MUST default to Delete and MAY be overridden by the caller.
- **async-confirm**: A confirmation MUST be available in a form that is awaited and returns the answer.
- **injectable-confirm**: An awaited ask MUST accept an injected confirmation closure and return its answer, so callers can be tested without UI.
- **choose-folder-is-a-sheet**: Choosing a folder MUST attach a sheet to the window and report the chosen location, or nothing if cancelled.
- **choose-folder-declines-without-window**: Choosing a folder with no window MUST report nothing.
- **folder-panel-allows-one-directory**: The folder chooser MUST allow exactly one selection and MUST allow directories only, never files.
- **report-trims-message**: Reporting an error MUST trim surrounding whitespace from the message before showing it.
- **report-without-window-logs**: Reporting an error with no window MUST log the message and show nothing.
- **report-shows-sheet**: Reporting an error with a window MUST show a warning sheet with a single OK button.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable: the component draws no views of its own; the sheets it raises are standard system dialogs.

## States

Not applicable: the component draws no views of its own; the sheets it raises are standard system dialogs.

## Accessibility

Not applicable: the component draws no views of its own; the sheets it raises are standard system dialogs.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-alerts-001 | confirm-declines-without-window | Ask for a destructive confirmation with no window | The answer is declined and a warning is logged |
| settings-alerts-002 | destructive-button-is-not-default | Build the destructive alert and inspect its buttons | Cancel answers Return; the destructive button has no key equivalent |
| settings-alerts-003 | escape-cancels | Press Escape on the built alert | Cancel is pressed |
| settings-alerts-004 | action-title-defaults-to-delete | Build the alert without an action title | The destructive button reads Delete |
| settings-alerts-005 | injectable-confirm | Ask with an injected closure that answers yes, then no | The awaited result is yes, then no |
| settings-alerts-006 | choose-folder-declines-without-window | Choose a folder with no window | Nothing is reported |
| settings-alerts-007 | folder-panel-allows-one-directory | Build the folder panel | Directories are allowed, files are not, and multiple selection is off |
| settings-alerts-008 | report-trims-message | Report a message padded with spaces and newlines | The text shown or logged has no surrounding whitespace |
| settings-alerts-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: An empty or whitespace-only error message is trimmed to empty and still reported.
- **Boundary values**: Not applicable: no numeric limits are defined.
- **Concurrent access**: Not applicable: all helpers are for use on the main thread.
- **Error states**: With no window every helper takes its safe path: confirmations decline, folder choice reports nothing, reports are logged.
- **Offline/disconnected state**: Not applicable: the component performs no networking.

## Configuration

The destructive confirmation takes a message, optional detail, an optional action title (default Delete) and the window to attach to. The folder chooser takes a prompt and a message. All are caller-supplied at call time; there is no persistent configuration.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

The default action title Delete and the Cancel and OK button titles are fixed English strings and are not localizable today; the caller supplies every other string (see Design Decisions).

## Accessibility Options

Not applicable: the component applies no animation, color-coded meaning or custom contrast handling of its own, so Reduce Motion, Increase Contrast and Differentiate Without Color need no handling here.

## Feature Flags

Not applicable: no feature-flag check applies; the component behaves the same unconditionally.

## Analytics

Not applicable: the component emits no analytics, tracking or telemetry.

## Privacy

Not applicable: the component stores and transmits nothing; error messages it logs are caller-supplied and stay in the local log.

## Logging

Declined confirmations, window-less folder requests and window-less error reports are logged at warning level under the AgenticToolkit subsystem with a settings-alerts category. Messages the caller supplies are logged as given.

## Platform Notes

- **SwiftUI**: Use `.confirmationDialog` or `.alert` with a destructive `Button(role: .destructive)` and a cancel-role button; use `.fileImporter` with directory content types for the folder choice.
- **Compose**: Use an `AlertDialog` with a destructive-styled confirm button and a dismiss button; use the Storage Access Framework `OpenDocumentTree` for the folder choice.
- **React/Web**: Use a modal `<dialog>` or an `alertdialog` role element, focus Cancel on open and close it on Escape; folder choice is `showDirectoryPicker()` where supported.
- **AppKit / UIKit (source)**: `ComposableSettings.Alerts` is a `@MainActor` enum with typealiases `Confirm`, `Report` and `ChooseFolder`. `confirmDestructive(_:detail:actionTitle:on:_:)` builds its alert in `makeDestructiveAlert`: the destructive button has an empty key equivalent, Cancel has Return, and an invisible zero-size button with the Escape key equivalent performs a click on Cancel. `ask(_:_:detail:)` awaits an injected `Confirm`. `chooseFolder(on:prompt:message:_:)` shows an `NSOpenPanel` sheet configured in `makeFolderPanel` (directories only, single selection). `report(_:on:)` shows an `NSAlert` warning sheet. Logging uses a `Logger` with subsystem AgenticToolkit and category ComposableSettings.Alerts.
- **WinUI 3**: Use a `ContentDialog` with `DefaultButton` set to Close (Cancel) and a styled primary button; use `FolderPicker` initialized with the window handle for the folder choice.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/SettingsAlerts.swift` |

## Design Decisions

**Decision**: The Delete, Cancel and OK button titles are hardcoded English.
**Rationale**: The helpers predate the localization pass; closing the gap needs string keys and a bundle the caller can override.
**Approved**: pending

**Decision**: Confirmations with no window decline instead of proceeding.
**Rationale**: Declining is the safe answer for a destructive action when nothing can be shown; the cost is that headless callers never get to confirm.
**Approved**: pending

**Decision**: Escape is wired by an invisible zero-size button rather than by making Cancel the only key-equivalent holder.
**Rationale**: The destructive button must not be the default, and the alert's own Escape handling is not relied on; the hidden button keeps Escape working in both cases.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the enum only builds and shows sheets and logs, taking every string and window from the caller, and holds no settings or layout state. Unit-test-coverage is partial: `SettingsAlertsTests.swift` has two tests, one for declining with no window and one for Escape still cancelling with Return on Cancel; the folder panel, error report and async paths have no test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
