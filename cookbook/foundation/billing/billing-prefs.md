---
id: 0175F0BB-F4BD-4F72-94C2-57B087AD9DF9
title: "Billing Preferences"
domain: adtoolkit://cookbook/foundation/billing/billing-prefs
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A per-pass snapshot of all billing settings, read live and clamped, with a transactional apply that re-derives history on a cutoff change."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - settings
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-user-settings
  - adtoolkit://cookbook/foundation/billing/billing-persistence
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing Preferences

## Overview

Reads every billing knob together as one immutable snapshot, once per pass rather than per session, so one session cannot derive at a 15-minute cutoff and the next at 60. Values live in the host's settings table under the host's key set and are read live, so a change applies on the next pass with no restart. Text is turned into values by the shared raw-setting rules and clamped to the shared limits on read. The apply operation writes whichever billing keys a request carries inside one write transaction and returns the snapshot now in force. Changing the effective idle cutoff makes the derived history stale, so every derived session's watermark is forgotten and re-split at the new cutoff.

## Behavioral Requirements

- **snapshot-all-knobs**: `snapshot` MUST read idle cutoff (seconds), granularity, default rate (cents), currency, rounding minutes, rounding mode, manual timer cap (seconds) and track-unassigned in one call.
- **defaults-and-clamp**: Each missing or unparseable value MUST fall to the shared default, and each numeric value MUST be clamped to its shared limit (idle cutoff 1 to 480 minutes, rounding 1 to 240 minutes, rate 0 to 10,000,000 cents, manual cap 1 to 24 hours).
- **granularity-fallback**: An unrecognised granularity MUST fall back to `day`.
- **read-failure-throws**: A failure to read the settings table MUST throw; it MUST NOT silently fall back to defaults.
- **units**: The snapshot MUST hold the cutoff in seconds and the cap in seconds; `wireForm` MUST convert back to minutes and hours.
- **rollup-options**: `rollupOptions` MUST carry granularity, default rate and currency into the rollup.
- **apply-allow-list**: `apply` MUST write only keys that belong to the billing key set and ignore all others.
- **apply-transaction**: `apply` MUST write all keys and compute before and after snapshots inside one write transaction, so a failure leaves nothing half-applied and is thrown.
- **store-verbatim**: `apply` MUST store values verbatim and rely on clamping at read, so the range lives in one place.
- **cutoff-change-resets**: If the effective idle cutoff differs after the write, `apply` MUST reset the derivation state of every session with derived time.
- **apply-returns-snapshot**: `apply` MUST return the snapshot in force after the write.

## Appearance

Not applicable — this is a settings read and write helper, not a visual component.

## States

Not applicable — this is a settings read and write helper, not a visual component.

## Accessibility

Not applicable — this is a settings read and write helper, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-prefs-001 | defaults-and-clamp | empty settings table | cutoff 900 s, granularity `day`, rounding 15 `up`, rate 0, `USD`, cap 28800 s, track-unassigned true |
| billing-prefs-002 | defaults-and-clamp | stored idle cutoff `0` | 60 s (clamped to 1 minute) |
| billing-prefs-003 | defaults-and-clamp | stored idle cutoff `9999` | 28800 s (clamped to 480 minutes) |
| billing-prefs-004 | granularity-fallback | stored granularity `weekly` | `day` |
| billing-prefs-005 | read-failure-throws | settings read throws | `snapshot` throws |
| billing-prefs-006 | apply-allow-list | `apply` with a billing key and an unrelated key | only the billing key is stored |
| billing-prefs-007 | cutoff-change-resets | `apply` changing the idle cutoff from 15 to 30 | derivation state of derived sessions is reset |
| billing-prefs-008 | cutoff-change-resets | `apply` changing only the currency | derivation state is not reset |
| billing-prefs-009 | units | snapshot with cutoff 900 s and cap 28800 s | `wireForm` has 15 minutes and 8 hours |

## Edge Cases

- A write failure inside `apply` rolls back every key written in it.
- Keys that are present in the request but not in the key set are skipped without error.
- An unrecognised value for a text setting (rounding mode, currency) is stored and returned as read; only numerics are clamped.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| keys | billing settings key set | from the persistence layer | Storage keys for the eight settings. |

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

Settings are stored locally in the host's settings table; nothing is transmitted by this code.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the type has no view layer.
- **Compose**: A suspending read of a preferences `DataStore` snapshot.
- **React/Web**: A function over a settings API returning a frozen object; wrap writes in one database transaction.
- **AppKit / UIKit**: Foundation-only enum namespace over the `BillingPersistence` protocol: `database.setting(for:)`, `setSetting`, `transaction`.
- **WinUI 3**: A service over `ApplicationData` or SQLite with `IDbTransaction`; read once per pass and pass the immutable record onward.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingPrefs.swift` |

## Design Decisions

**Decision**: No test exercises `snapshot` or `apply` directly.
**Rationale**: Behavior is covered only indirectly through the store's passes; tests of clamping, fallbacks, the allow-list and the cutoff-change reset need an in-memory persistence stub.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: the type owns only reading, clamping and applying the knobs; storage is the persistence protocol and text parsing is the shared raw-setting helper. unit-test-coverage fails: a search of the Tests directories finds no test that references the preferences type.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
