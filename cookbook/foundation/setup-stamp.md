---
id: 469A222D-AF34-409F-9675-9B1F2659BAEC
title: "Setup Stamp"
domain: adtoolkit://cookbook/foundation/setup-stamp
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A stamp file recording which bundle version last completed per-user setup, so an app knows when setup must run again."
platforms:
  - swift
  - macos
tags:
  - foundation
  - setup
  - versioning
  - files
depends-on: []
related:
  - adtoolkit://cookbook/foundation/file-system
references: []
approved-by: ""
approved-date: ""
---

# Setup Stamp

## Overview

Records which bundle version last completed per-user setup. An updater replaces the bundle but not what setup installed around it, such as a launch agent, command-line links or plugins; comparing the running bundle's version to this stamp is how an app knows setup must run again. Any difference counts: a downgrade needs setup as much as an upgrade does.

## Behavioral Requirements

- **missing-needs-setup**: Setup MUST be reported as needed when the stamp file is missing or cannot be read as UTF-8 text.
- **equal-version-no-setup**: Setup MUST NOT be reported as needed when the recorded version, trimmed of whitespace and newlines, equals the running bundle version exactly.
- **any-difference-needs-setup**: Setup MUST be reported as needed for any difference between the recorded and running versions, whether older or newer.
- **whitespace-ignored**: Leading and trailing whitespace and newlines in the stamp file MUST be ignored when comparing.
- **record-writes-version**: Recording MUST write the bundle version as UTF-8 text to the stamp file, atomically, and MUST create the stamp file's parent directory, with intermediate directories, when it does not exist.
- **record-propagates-errors**: Recording MUST propagate a directory-creation or write failure to the caller rather than swallowing it.
- **default-location**: The default stamp location MUST be a file named `last-setup-version` inside a directory named by the caller, inside the user's application support directory.

## Appearance

Not applicable: The stamp is not a visual component.

## States

Not applicable: The stamp is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The stamp presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| setup-stamp-001 | missing-needs-setup | Check a stamp URL that does not exist. | Setup is needed (test: testMissingStampNeedsSetup). |
| setup-stamp-002 | record-writes-version, equal-version-no-setup | Record `1.2.3`, then check with bundle version `1.2.3`. | Setup is not needed (test: testRecordedSameVersionDoesNotNeedSetup). |
| setup-stamp-003 | any-difference-needs-setup | Record `1.2.3`, then check with `1.2.4` and with `1.2.2`. | Setup is needed in both directions (test: testDifferentVersionNeedsSetupInEitherDirection). |
| setup-stamp-004 | whitespace-ignored | Write `1.2.3\n` to the stamp, then check `1.2.3`. | Setup is not needed (test: testWhitespaceInStampIsIgnored). |
| setup-stamp-005 | default-location | Ask for the default URL with directory name `MyApp`. | The path ends with `Library/Application Support/MyApp/last-setup-version` (test: testDefaultURLShape). |
| setup-stamp-006 | record-writes-version | Record a version to a URL whose parent directory does not exist. | The directory is created and the file written. |

## Edge Cases

- **Null / empty input**: An empty stamp file reads as an empty recorded version, which differs from any real bundle version, so setup is needed; recording an empty version string writes an empty file.
- **Boundary values**: The comparison is exact string equality after trimming, so `1.2.3` and `1.2.3.0` differ.
- **Concurrent access**: The write is atomic, so a concurrent reader sees the old or the new stamp, never a partial one; two simultaneous recorders are last-writer-wins.
- **Error states**: Reading never throws; any read failure means setup is needed. Recording throws on any filesystem failure.
- **Offline / disconnected state**: Not applicable: The stamp has no network access.
- **Cancellation**: Not applicable: The stamp has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| supportDirectoryName | text | none, required | The directory name under the application support directory that holds the stamp. |

The stamp reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The stamp defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The stamp contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The stamp presents no UI.

## Feature Flags

Not applicable: The stamp contains no feature-flag reference.

## Analytics

Not applicable: The stamp contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The stamp calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; the write uses `Data.write(to:options: .atomic)` and the default URL is under `applicationSupportDirectory`.
- **Compose**: Store the stamp in `filesDir` (or a DataStore key) and compare the app's `versionName`; write with `AtomicFile`.
- **React/Web**: Use a `localStorage` key for the stamp and compare against the build's version constant; there is no file, so atomicity is free.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Write the stamp to `ApplicationData.Current.LocalFolder` using `FileIO.WriteTextAsync`, compare against `Package.Current.Id.Version` formatted as a string, and treat any `FileNotFoundException` as needs-setup.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/SetupStamp.swift` |

## Design Decisions

**Decision**: Any version difference triggers setup, including a downgrade.
**Rationale**: A downgraded bundle may expect an older layout around it just as an upgraded one expects a newer one, so equality is the only safe skip.
**Approved**: pending

**Decision**: A read failure is treated as setup needed.
**Rationale**: An unreadable stamp cannot prove setup completed; re-running idempotent setup is cheaper than skipping a required one.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |

`separation-of-concerns` passes because the type only reads, compares and writes the stamp; what setup does is the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/FileSystem/SetupStampTests.swift` covers a missing stamp, the same recorded version, a different version in either direction, ignored whitespace and the default URL shape.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
