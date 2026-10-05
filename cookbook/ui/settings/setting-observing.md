---
id: 64C9047D-53A2-4912-8817-2F35372E505F
title: "Setting Observing"
domain: adtoolkit://cookbook/ui/settings/setting-observing
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A one-value binding contract for settings views: read and write a value, and be told after a write has landed."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - binding
depends-on: []
related:
  - adtoolkit://cookbook/ui/settings/views/value-row-view
references: []
approved-by: ""
approved-date: ""
---

# Setting Observing

## Overview

Setting observing is the contract a settings view binds to instead of a concrete store. It exposes one current value that can be read and written, and an optional change callback that is told after a write has landed. A persisted-settings observer and a closure-backed observer both satisfy it, so a view can be driven by user defaults or by plain getter and setter closures without knowing which.

## Behavioral Requirements

- **reads-through-source**: Reading the value MUST return what the underlying source currently holds, by asking the source at read time rather than caching a copy.
- **writes-through-source**: Writing the value MUST hand the new value to the underlying source before anything is reported.
- **notifies-after-write**: After a write, the observer MUST invoke its change callback, if one is set, with the value that was written, and the source MUST already hold that value when the callback runs.
- **notifies-on-main-queue**: The change callback MUST be delivered through the main dispatch queue and not through a run-loop mode, so it still arrives while the user is tracking a mouse drag.
- **callback-is-optional**: A write with no change callback assigned MUST succeed and report nothing.
- **skips-delivery-when-released**: A delivery still queued when the observer is released MUST be dropped without effect.
- **closure-form**: The component MUST provide a form built from a getter, a setter and an optional change callback, so a caller can bind a view to values that are not in the settings store.
- **persisted-form-conforms**: The persisted-settings observer MUST satisfy the same contract as the closure form.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable: the component is a data-binding contract with no visual surface.

## States

Not applicable: the component is a data-binding contract with no visual surface.

## Accessibility

Not applicable: the component is a data-binding contract with no visual surface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| setting-observing-001 | reads-through-source | Closure observer whose getter returns 3; read the value | 3, and the getter is asked on every read |
| setting-observing-002 | writes-through-source | Write 7 to a closure observer | The setter receives 7 |
| setting-observing-003 | notifies-after-write | Set a change callback, write 9, then let the main queue drain | The callback fires once with 9, and a read inside it returns 9 |
| setting-observing-004 | notifies-on-main-queue | Write while the main queue is draining | The callback has not yet fired when the write returns; it fires on the next main-queue turn |
| setting-observing-005 | callback-is-optional | Write a value with no callback assigned | No error; the setter still receives the value |
| setting-observing-006 | closure-form | Bind a checkbox view to a closure observer and toggle it | The setter is called and the checkbox reflects the stored value |
| setting-observing-007 | persisted-form-conforms | Use the persisted-settings observer wherever the contract is required | It reads, writes and notifies like the closure form |
| setting-observing-008 | skips-delivery-when-released | Write, release the observer before the queue drains | The callback never fires and nothing fails |
| setting-observing-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: Not applicable: the contract is generic over its value type; it adds no null handling of its own.
- **Boundary values**: Not applicable: no value range is defined by the contract.
- **Concurrent access**: The contract is main-thread only. A write issued from another thread is outside it.
- **Error states**: Not applicable: neither read nor write can report a failure; a failing source is the source's concern.
- **Offline/disconnected state**: Not applicable: the component performs no networking.
- **Callback replaced after write**: A callback assigned after a write is queued but before it drains is the one that fires, because the callback is read when the delivery runs.

## Configuration

Not applicable: the contract takes no options; the closure form takes a getter, a setter and an optional change callback at construction.

## Deep Linking

Not applicable: the component has no navigable identity of its own; no route or resource a deep link could target.

## Localization

Not applicable: the component renders no text and defines no string keys.

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

- **SwiftUI**: Expose a state binding (`Binding<Value>`) or an observable object; SwiftUI re-reads on change, so the explicit change callback is rarely needed.
- **Compose**: Use a `MutableState<Value>` or a `StateFlow`; collecting the flow replaces the change callback.
- **React/Web**: Use a store with a subscribe function (a signal, a Redux selector or `useSyncExternalStore`); notify on the next task turn to match the deferred delivery.
- **AppKit / UIKit (source)**: `SettingObserving` is a `@MainActor` protocol constrained to `AnyObject` with `value` and `onChange` members. `ClosureSettingObserver<Value>` implements the closure form with `init(get:set:onChange:)`; `UserSettingObserver` conforms through an extension. A write calls the setter, then schedules `DispatchQueue.main.async` and re-enters the main actor with `MainActor.assumeIsolated` before calling `onChange`. The main dispatch queue is used rather than `RunLoop.main` because run-loop-mode delivery stalls during event tracking. Views re-read the value inside the callback.
- **WinUI 3**: Implement as an interface with a `Value` property and a `ValueChanged` event; raise the event through `DispatcherQueue.TryEnqueue` on the UI thread so delivery follows the write, matching the deferred callback.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/ViewModels/SettingObserving.swift` |

## Design Decisions

**Decision**: Change delivery is deferred by one main-queue turn, so a read immediately after a write sees the new value but the callback has not yet fired.
**Rationale**: Deferring lets a write made during a tracking loop finish before views redraw; the cost is that a caller cannot rely on the callback having run when the write returns. A synchronous mode would need a second contract.
**Approved**: pending

**Decision**: The observer holds a single change callback slot, so only one listener is supported.
**Rationale**: Settings views each own their observer, so one slot has been enough; supporting several listeners would need a subscription list and an unsubscribe path.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Separation-of-concerns is passed: the protocol and closure observer only read, write and notify, with no view, storage or layout logic. Unit-test-coverage is passed: `SettingObservingTests.swift` covers the closure observer reading, writing and notifying, the callback firing after the write lands, a view-model closure initializer driving a checkbox, and the persisted-settings observer conforming.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
