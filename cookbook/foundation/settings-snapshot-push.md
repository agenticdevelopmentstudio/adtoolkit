---
id: 402E0AB0-6488-403B-BC43-FBC9145A9A27
title: "Settings Snapshot Push"
domain: adtoolkit://cookbook/foundation/settings-snapshot-push
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Mirrors a group of settings into another process by sending a full idempotent snapshot on change, at startup and on every reconnect, with bounded retry and supersession."
platforms:
  - swift
  - macos
tags:
  - foundation
  - settings
  - sync
  - ipc
  - retry
depends-on: []
related:
  - adtoolkit://cookbook/foundation/settings-storage
  - adtoolkit://cookbook/foundation/raw-setting
references: []
approved-by: ""
approved-date: ""
---

# Settings Snapshot Push

## Overview

Mirrors a group of settings into another process: on any change, at startup, and on every reconnect, the whole idempotent snapshot is sent. It sends a full snapshot rather than a delta, so a receiver that was down for one of the changes is corrected by the next push rather than staying half-configured. A newer push supersedes one still retrying, so a stale body can never land after a fresh one, and the retry is deliberately bounded because a dropped push leaves the receiver on its last-known state until the next change re-pushes. The reconnect handler is registered once per instance and is inert while the push is stopped. What the snapshot holds, how it is encoded and how it travels are the caller's; the engine (observe, snapshot, supersede, bounded retry, re-push on reconnect) is this one copy.

## Behavioral Requirements

- **caller-supplied-pieces**: The push MUST be built from a label naming the channel in log lines, a logger, a snapshot builder that returns the body or nothing, a sender that returns whether the receiver took the body, and a reconnect registrar; it MUST NOT decide what the snapshot holds, how it is encoded or how it travels.
- **start-observes-and-pushes**: Starting MUST begin observing the given settings, MUST push the snapshot immediately (observers fire only on change and the receiver may have restarted), and MUST re-push on every change of an observed setting.
- **mixed-type-start**: Starting MUST also accept a builder that is handed the change handler and returns the observers it created, for settings of mixed types, and MUST keep those observers alive until stop.
- **start-once**: A repeat start while observing MUST be ignored and MUST log a warning naming the label.
- **reconnect-registered-once**: The reconnect handler MUST be registered once per instance, on the first start, and MUST NOT be registered again by later starts.
- **reconnect-repushes**: On every reconnect while observing, the handler MUST push the current snapshot; while stopped, the handler MUST do nothing.
- **stop**: Stopping MUST stop observing, release the observers and cancel a push still retrying; the reconnect handler MUST stay registered but inert until the next start.
- **snapshot-failure-not-sent**: When the snapshot builder returns nothing, the push MUST log an error naming the label and MUST NOT send anything or cancel an in-flight push.
- **newest-supersedes**: A push MUST cancel any push still retrying before starting its own, so a stale body never lands after a fresh one.
- **bounded-retry**: A push MUST attempt delivery once per configured backoff, waiting that many nanoseconds before each attempt; the default MUST be at once, then after 0.5 seconds, then after 1.5 seconds. It MUST stop at the first success, and after the last failed attempt MUST log an error that the receiver keeps its prior state.
- **superseded-stops-attempts**: A push that was cancelled MUST stop before its next attempt, without sending.
- **failure-logged-per-attempt**: Each failed attempt MUST log a warning naming the label and the attempt number out of the total.
- **sorted-key-encoding**: The engine MUST offer a helper that encodes a value as JSON with sorted keys, giving a byte-stable body, and returning nothing when encoding fails.
- **await-pending**: The engine MUST offer a way to await the most recent push, intended for tests.
- **main-context**: The push MUST be confined to the main UI context, so observation and snapshots read settings from the context that owns them.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable: The push engine is not a visual component.

## States

Not applicable: The push engine is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The push engine presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-snapshot-push-001 | start-observes-and-pushes, reconnect-repushes | Start with a sender that always succeeds and a snapshot that encodes a value of 1, change the value the snapshot reads to 2 (the test fires no setting-change event), then trigger a reconnect. | The first body is the snapshot with value 1; after the reconnect the last body is the snapshot with value 2 (test: testPushesOnStartAndOnEveryReconnect). |
| settings-snapshot-push-002 | bounded-retry | Three backoffs; the sender fails twice, then succeeds. | The third attempt lands and exactly one body is received (test: testRetriesABoundedNumberOfTimes). If every attempt failed, an error is logged after the third and no further attempts are made. |
| settings-snapshot-push-003 | stop, reconnect-repushes | Start, let the first push finish, stop, then trigger a reconnect. | The reconnect does not push; one body total (test: testAStoppedPushIgnoresReconnects). |
| settings-snapshot-push-004 | sorted-key-encoding | Encode a value with keys `b` and `a`. | The JSON body lists `a` before `b` (test: testEncodesWithSortedKeys). |
| settings-snapshot-push-005 | newest-supersedes | Trigger a push whose sender is slow and failing, then change a setting. | The first push is cancelled and only the second body lands. |
| settings-snapshot-push-006 | snapshot-failure-not-sent | The snapshot builder returns nothing. | An error is logged and the sender is not called. |
| settings-snapshot-push-007 | start-once | Call start twice with the same settings. | The second call logs a warning and does not push again or register another reconnect handler. |
| settings-snapshot-push-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null / empty input**: An empty settings list is valid and still pushes the snapshot at start; an empty backoff list attempts nothing and logs the exhausted-retry error immediately.
- **Boundary values**: The default backoff list has three entries, the first being zero, so the first attempt is immediate; a backoff of zero skips the wait but still honors cancellation.
- **Concurrent access**: The push state is confined to the main UI context; the send closure is run off it and receives its body by value.
- **Error states**: A failed send is retried up to the backoff count and then logged and dropped; the receiver keeps its prior state until the next change or reconnect. A snapshot that cannot be built is logged and skipped.
- **Offline / disconnected state**: A failing sender models an unreachable receiver; the retry is bounded and the reconnect handler re-pushes when the receiver returns.
- **Cancellation**: Stopping or starting a newer push cancels the retrying one; cancellation is checked after each wait and before each attempt.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| label | text | none, required | Names the channel in log lines. |
| backoffs | list of nanosecond waits | at once, 0.5 s, 1.5 s | The wait before each attempt; its length is the attempt count. |

The push engine reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The push engine defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The push engine contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The push engine presents no UI.

## Feature Flags

Not applicable: The push engine contains no feature-flag reference.

## Analytics

Not applicable: The push engine contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

- **Log lines**: Warnings for a repeated start and for each failed attempt; errors for an unbuildable snapshot and for exhausted retries. The label is logged publicly and carries no setting content.

## Platform Notes

- **SwiftUI**: The source file imports `Foundation` and the logging framework; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. The push is `@MainActor`, observers are the settings-store observer type, and the retry engine is `Task`-based with `Task.sleep`.
- **Compose**: Use a `CoroutineScope` on the main dispatcher, a `Job` for the retry, and `flow.collect` on each setting to trigger `push()`; supersession is `job.cancel()` before launching.
- **React/Web**: A class with an `AbortController` per push: abort the previous controller before starting, check `signal.aborted` after each `await sleep(backoff)`, and listen to the transport's `online` or reconnect event to re-push.
- **AppKit / UIKit**: Identical to the SwiftUI note: the observers in the AppKit use are `UserSettingObserver` instances that defer to the next main-queue turn, and the reconnect registrar comes from the XPC connection wrapper.
- **WinUI 3**: Keep the push on the UI `DispatcherQueue`; observe settings via `INotifyPropertyChanged`, send through `NamedPipeClientStream` or an AppService connection, supersede with a `CancellationTokenSource` per push, and use `Task.Delay` for each backoff.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/SettingStorage/SettingsSnapshotPush.swift` |

## Design Decisions

**Decision**: A full snapshot is sent every time, never a delta.
**Rationale**: A receiver that was down for one change is corrected by the next push, which a delta would leave half-configured; the cost is a slightly larger body, which settings groups can afford.
**Approved**: pending

**Decision**: Retry is bounded, not infinite.
**Rationale**: A dropped push leaves the receiver on its last-known state until the next change re-pushes, so endless retry would only keep a stale body alive against a newer one.
**Approved**: pending

**Decision**: The reconnect handler stays registered after stop and is inert.
**Rationale**: The registrar offers no way to unregister, so one registration per instance with an observing check avoids both duplicate handlers and leaked pushes.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`separation-of-concerns` passes because the engine owns observe, snapshot, supersede, bounded retry and reconnect, while the snapshot contents, encoding and transport are supplied by the caller. `unit-test-coverage` passes because `SettingsSnapshotPushTests` in `AgenticToolkitCoreTests/SettingsStore/RawSettingTests.swift` covers pushing on start and on every reconnect, bounded retry, ignoring reconnects while stopped, and sorted-key encoding; the supersession and snapshot-failure paths have no dedicated assertion.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
