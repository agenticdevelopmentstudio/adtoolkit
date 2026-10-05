---
id: C1CAA827-F7F1-4E69-B4C6-ADBFEF22E636
title: "Billing User Settings"
domain: adtoolkit://cookbook/foundation/billing/billing-user-settings
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The eight billing knobs as live, namespaced user settings with shared defaults."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - settings
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-prefs
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing User Settings

## Overview

A main-thread holder of the eight billing settings: idle cutoff minutes, granularity, rounding minutes, rounding mode, default rate in cents, currency, manual timer cap in hours, and track-unassigned. Each is a live user setting stored under a key from one app's billing settings key set, so the app decides only the key prefix (and therefore the namespace in the settings table). Defaults come from the shared billing defaults, the same numbers the daemon falls back to, so the settings pane, the wire and the deriver share one set of values.

## Behavioral Requirements

- **eight-settings**: The holder MUST expose exactly eight settings: `idleCutoffMinutes` (int), `granularity` (string), `roundingMinutes` (int), `roundingMode` (string), `defaultRateCents` (int), `currency` (string), `manualTimerCapHours` (int), `trackUnassigned` (bool).
- **keys-from-app**: Each setting MUST be stored under the matching key of the injected key set.
- **defaults-shared**: Each setting's default MUST be the shared billing default: idle cutoff 15, granularity `day`, rounding 15 minutes, mode `up`, rate 0 cents, currency `USD`, manual cap 8 hours, track-unassigned true.
- **rate-integer-cents**: The default rate MUST be integer cents per hour, never a floating-point value.
- **granularity-groups-entries-only**: `granularity` (`day` or `run`) MUST NOT change what is derived or how segments are stored, which is always whole; it only decides how the rollup groups segments into entries on later passes, so it can be switched at any time.
- **idle-cutoff-affects-derivation**: `idleCutoffMinutes` MUST be the one setting that changes what gets derived: a gap longer than it ends a run.
- **manual-cap-flags**: A manual timer running longer than `manualTimerCapHours` MUST be flagged, never truncated.
- **main-thread**: The holder MUST be used from the main thread only.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable — this is a non-visual settings holder, not a visual component.

## States

Not applicable — this is a non-visual settings holder, not a visual component.

## Accessibility

Not applicable — this is a non-visual settings holder, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-user-settings-001 | defaults-shared | new holder, read `idleCutoffMinutes` | 15 |
| billing-user-settings-002 | defaults-shared | new holder, read `granularity` | `day` |
| billing-user-settings-003 | defaults-shared | new holder, read `roundingMinutes` and `roundingMode` | 15 and `up` |
| billing-user-settings-004 | defaults-shared | new holder, read `defaultRateCents`, `currency` | 0 and `USD` |
| billing-user-settings-005 | defaults-shared | new holder, read `manualTimerCapHours`, `trackUnassigned` | 8 and true |
| billing-user-settings-006 | keys-from-app | holder built with prefix `x`, set `currency` to `EUR` | the settings table holds `EUR` under the key set's currency key |
| billing-user-settings-007 | keys-from-app | two holders with different key sets | writes to one do not change the other |
| billing-user-settings-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- A stored value of the wrong type falls to the setting's default.
- Out-of-range stored values are not clamped by the holder; the billing preferences snapshot clamps them to the shared ranges when it reads the same keys.
- Two holders built from the same key set observe each other's writes through the settings store.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| keys | billing settings key set | required | Supplies the storage key of each of the eight settings. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Settings are stored locally in the app's settings table; the rate and currency are business data that stay on the device unless the app syncs the settings table.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Settings are bound to the pane through the holder's `UserSetting` values; no SwiftUI types are used by the holder.
- **Compose**: A `DataStore`-backed preference per setting, exposed as `Flow`.
- **React/Web**: A typed wrapper over a settings store (for example `localStorage` or a server-synced table) with change notification.
- **AppKit / UIKit**: A `@MainActor final class` whose properties are generic `UserSetting<T>` values; AppKit panes bind to them.
- **WinUI 3**: `ApplicationData.Current.LocalSettings` values behind a class implementing `INotifyPropertyChanged`; marshal writes to the UI thread through `DispatcherQueue`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingUserSettings.swift` |

## Design Decisions

**Decision**: Values are not validated or clamped when written through the holder.
**Rationale**: Clamping happens when the preferences snapshot reads the keys, so the range lives in one place; validating at the holder would need the settings pane to surface errors.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: the holder only binds keys to defaults; the key set, defaults and storage are injected or shared. unit-test-coverage is partial: `BillingSettingsPanelTests`, `ClientsWindowControllerTests` and `ProjectsWindowControllerTests` in `AgenticToolkitMacOSTests` build and use the holder, but no test asserts the defaults or key mapping directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
