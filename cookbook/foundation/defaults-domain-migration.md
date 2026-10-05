---
id: 21CBC5BD-350A-4AB6-8C37-3290ACB70460
title: "Defaults Domain Migration"
domain: adtoolkit://cookbook/foundation/defaults-domain-migration
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A one-time copy of an app's saved settings from a legacy preferences domain to a new one after a bundle-identifier change."
platforms:
  - swift
  - macos
tags:
  - foundation
  - settings
  - migration
  - defaults
depends-on: []
related:
  - adtoolkit://cookbook/foundation/settings-storage
references: []
approved-by: ""
approved-date: ""
---

# Defaults Domain Migration

## Overview

Carries an app's saved settings across a bundle-identifier change. The standard preferences domain is the bundle identifier, so renaming the bundle silently starts the app on an empty domain and every setting the user made is gone. The migration copies the legacy domain into the new one exactly once: only while the new domain holds nothing, so a user who has already changed a setting under the new identifier is never overwritten. The legacy domain is left in place, because it costs a small file and deleting it would make a downgrade lose everything instead.

## Behavioral Requirements

- **copy-when-new-empty**: The migration MUST copy every key of the legacy domain into the new domain when the new domain holds nothing and the legacy domain holds at least one key, and MUST then report that settings were copied.
- **never-overwrite**: The migration MUST NOT change the new domain when it already holds any setting, and MUST report that nothing was copied.
- **nothing-to-copy**: The migration MUST report that nothing was copied, and change nothing, when the legacy domain is absent or empty.
- **same-domain-noop**: The migration MUST do nothing when the legacy and new domain names are equal.
- **legacy-left-in-place**: The migration MUST NOT delete or modify the legacy domain.
- **idempotent**: Running the migration again after a successful copy MUST do nothing and report that nothing was copied, because the new domain is now non-empty.
- **store-injectable**: The preferences store MUST be an optional parameter defaulting to the standard user preferences, so the migration is testable against an isolated store.
- **result-discardable**: The returned flag MUST be optional to use: a caller that only wants the side effect may ignore it.

## Appearance

Not applicable: The migration is not a visual component.

## States

Not applicable: The migration is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The migration presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| defaults-domain-migration-001 | copy-when-new-empty | Legacy domain holds `{theme: dark}`; new domain is empty. | The new domain holds `{theme: dark}`; the call reports true (test: testCopiesLegacySettingsIntoAnEmptyDomain). |
| defaults-domain-migration-002 | never-overwrite | Legacy holds `{theme: dark}`; new holds `{theme: light}`. | The new domain is unchanged; the call reports false (test: testNeverOverwritesADomainThatAlreadyHoldsSettings). |
| defaults-domain-migration-003 | nothing-to-copy | Legacy domain is absent. | Nothing changes; reports false (test: testDoesNothingWithoutLegacySettings). |
| defaults-domain-migration-004 | idempotent | Run the migration twice with a populated legacy and an empty new domain. | First call reports true; second reports false and changes nothing (test: testIsIdempotent). |
| defaults-domain-migration-005 | legacy-left-in-place | After a successful copy, read the legacy domain. | It still holds its original keys. |
| defaults-domain-migration-006 | same-domain-noop | Migrate from `com.example.app` to `com.example.app`. | Reports false; nothing changes. |
| defaults-domain-migration-007 | nothing-to-copy | Legacy domain exists but holds no keys. | Reports false; the new domain stays empty. |

## Edge Cases

- **Null / empty input**: An empty or absent legacy domain is a no-op; an empty domain name is passed through to the store without validation.
- **Boundary values**: A new domain holding even a single key blocks the copy entirely; there is no per-key merge.
- **Concurrent access**: The check and the write are two separate store calls with no lock, so two processes migrating the same domain at once could both copy; callers run it once at launch.
- **Error states**: The migration has no failing path; it returns a flag and never throws.
- **Offline / disconnected state**: Not applicable: The migration has no network access.
- **Cancellation**: Not applicable: The migration has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| legacyDomain | text | none, required | The previous domain (bundle identifier) to read from. |
| domain | text | none, required | The new domain to write to. |
| defaults | preferences store | standard user preferences | The store to read and write; injectable for tests. |

The migration reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The migration defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The migration contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The migration presents no UI.

## Feature Flags

Not applicable: The migration contains no feature-flag reference.

## Analytics

Not applicable: The migration contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The migration calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with one static function using `UserDefaults.persistentDomain(forName:)` and `setPersistentDomain(_:forName:)`.
- **Compose**: Android has no bundle-identifier-keyed domain; the analog is migrating a `SharedPreferences` file or DataStore after a package rename by copying all entries once, guarded by the new store being empty.
- **React/Web**: Browser storage is keyed by origin; after an origin change copy `localStorage` entries from the old origin through a cross-origin message, only while the new origin's storage is empty.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Packaged apps keep settings in `ApplicationData.Current.LocalSettings` under the package family name; after a package-identity change, copy the old container's values once, guarded by the new `LocalSettings.Values` being empty, and leave the old data in place.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/SettingStorage/DefaultsDomainMigration.swift` |

## Design Decisions

**Decision**: The legacy domain is never deleted after migration.
**Rationale**: A downgrade to the old build would otherwise lose every setting instead of just the ones changed since; the cost of keeping it is one small preferences file.
**Approved**: pending

**Decision**: The copy is all-or-nothing and gated on the new domain being empty, with no per-key merge.
**Rationale**: A merge would have to decide which side wins for each key; refusing to touch a non-empty domain guarantees a user who has already changed a setting under the new identifier is never overwritten.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |

`separation-of-concerns` passes because the type does one thing, the one-time domain copy, and leaves when to call it and what the settings mean to the host. `unit-test-coverage` passes because `AgenticToolkitCoreTests/SettingsStore/DefaultsDomainMigrationTests.swift` covers copy into an empty domain, refusal to overwrite, no legacy settings and idempotence.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
