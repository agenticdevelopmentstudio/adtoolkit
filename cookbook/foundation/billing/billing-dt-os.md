---
id: ED610AA4-2717-4242-A8B9-C4616377DBD9
title: "Billing DTOs"
domain: adtoolkit://cookbook/foundation/billing/billing-dt-os
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The billing data shapes shared by app and daemon: clients, projects, repos, segments, entries, overview, audit, preferences, plus wire sentinels, settings keys, defaults, limits and refusal sentences."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - dto
  - wire
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-xpc-client
  - adtoolkit://cookbook/foundation/billing/billing-xpc-protocol
  - adtoolkit://cookbook/foundation/billing/billing-model
  - adtoolkit://cookbook/foundation/billing/billing-prefs
references: []
approved-by: ""
approved-date: ""
---

# Billing DTOs

## Overview

The one definition of every billing record and value that crosses between an app and a daemon, so neither side redefines a shape. Records are immutable values with every optional contact field defaulting to an empty string so form bindings never unwrap. Billing status is three states in one direction (unbilled, billed, paid) and anything past unbilled locks an entry. An entry snapshots rate, currency and rounding at write time so a later rate change never rewrites history. The overview never sums across currencies. The same file holds the small shared constants both sides must spell identically: the failure sentinels, the settings keys, the default and clamp ranges for the preference knobs, and the sentences a refused write carries.

## Behavioral Requirements

- **immutable-values**: Every record MUST be an immutable value with equality; the client, project, repo, segment and entry records MUST also carry an identifier.
- **three-statuses**: Billing status MUST be exactly unbilled, billed and paid; `next` MUST advance one step forward and be nil at paid; any status other than unbilled MUST lock the entry.
- **optional-strings-empty**: Unset contact, note and path fields MUST be the empty string, not null; unset foreign keys, rates and links MUST be null.
- **segment-origin**: A segment's origin MUST be `auto` or `manual`; the two spellings MUST be defined once; a segment with an empty end MUST be running; a manual segment MUST be one someone started.
- **segment-zone**: A segment MUST carry the zone captured when it was created, and local-day bucketing MUST use that zone.
- **entry-snapshot**: An entry MUST carry raw seconds, billed seconds, rate, currency, amount, rounding minutes and rounding mode as written, plus the client denormalised at write time.
- **entry-group-key**: An entry's group key MUST be empty or `rate:<cents>` at day granularity and `<session>|<start>` or the segment id at run granularity, and is part of the uniqueness key.
- **supplement-link**: An entry MAY name the entry it supplements.
- **overview-per-currency**: The overview MUST carry one bucket set per currency in use, most entries first, and MUST NOT sum across currencies; its top-level buckets MUST be the first currency's.
- **overview-compat**: The overview MUST decode when the per-currency list is absent, as an empty list.
- **audit-append-only**: An audit row MUST record entry, instant, field, old value, new value and a source of `auto` or `user`.
- **wire-sentinels**: A failed list read MUST be signalled by the single row `{"billing_read_failed":true}` and a failed count by -1.
- **settings-keys**: Settings keys MUST be built from one app-chosen prefix plus fixed key names, and the allow-list MUST contain exactly the eight billing keys.
- **defaults**: Unconfigured defaults MUST be: idle cutoff 15 minutes, day granularity, rounding 15 minutes up, rate 0, currency USD, manual timer cap 8 hours, track unassigned true.
- **limits**: Preference limits MUST be: idle cutoff 1 to 480 minutes, rounding 1 to 240, rate 0 to 10,000,000 cents, manual cap 1 to 24 hours; `clamp` MUST return the nearest bound.
- **refusal-sentences**: The refusal sentences MUST be defined once and shared by the daemon and any test double; a repo claim sentence MUST name the root and either "any branch" or the branch.

## Appearance

Not applicable — this is a non-visual data model, not a visual component.

## States

Not applicable — this is a non-visual data model, not a visual component.

## Accessibility

Not applicable — this is a non-visual data model, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-dt-os-001 | three-statuses | status unbilled, billed, paid | next is billed, paid, nil |
| billing-dt-os-002 | three-statuses | status billed | locks the entry |
| billing-dt-os-003 | three-statuses | status unbilled | does not lock |
| billing-dt-os-004 | segment-origin | segment with empty end | running |
| billing-dt-os-005 | segment-origin | segment origin `manual` | manual |
| billing-dt-os-006 | overview-per-currency | USD and EUR entries | two currency rows; top-level buckets equal the first row |
| billing-dt-os-007 | overview-compat | overview JSON without by_currency | decodes with an empty list |
| billing-dt-os-008 | wire-sentinels | failed list read | `{"billing_read_failed":true}` |
| billing-dt-os-009 | settings-keys | prefix `app_billing_` | idle key `app_billing_idle_cutoff_minutes`; allow-list of 8 |
| billing-dt-os-010 | limits | clamp 9999 to the idle range | 480 |
| billing-dt-os-011 | limits | clamp 0 to the rounding range | 1 |
| billing-dt-os-012 | defaults | no configuration | rounding 15, mode up, currency USD |
| billing-dt-os-013 | refusal-sentences | claim of `/r` on no branch | "/r (any branch) already belongs to another project." |
| billing-dt-os-014 | entry-snapshot | encode then decode an entry as snake_case JSON | equal to the original |

## Edge Cases

- A running segment has an empty end and zero seconds.
- Amounts in different currencies are never combined.
- A reader that knows one currency reads the top-level buckets and still gets a true figure.
- A daemon that predates per-currency rows still decodes.
- A typo in a copied origin string would silently never match, hence the shared constants.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| prefix | string | app-chosen | Namespace for the settings keys. |
| defaults and limits | constants | as listed | Shared by app and daemon. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Refusal sentences and the default currency are hardcoded English and USD.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Records carry client names, contacts and rates; they stay on the machine between the app and its own daemon.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; these are plain values a view binds to.
- **Compose**: Kotlin data classes with `kotlinx.serialization` and `@SerialName` snake_case.
- **React/Web**: TypeScript interfaces or zod schemas with snake_case wire keys.
- **AppKit / UIKit**: Swift `Codable`, `Sendable`, `Equatable` structs; keys convert through `.convertToSnakeCase`; the overview has a custom decoder using `decodeIfPresent`.
- **WinUI 3**: C# records with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower`; `required` members for non-optional fields.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingDTOs.swift` |

## Design Decisions

**Decision**: Wire fields are plain strings (status, origin, rounding mode, granularity).
**Rationale**: Strings keep the wire stable and forward compatible; the cost is that typos compile, which the shared origin constants and the status enum offset where it matters.
**Approved**: pending

**Decision**: Refusal sentences are English constants.
**Rationale**: They travel verbatim to an alert; localizing them would need a code-per-refusal.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: the file holds shapes and shared constants only; storage, rules and transport are elsewhere. unit-test-coverage is partial: `BillingDTOsTests` covers the entry and segment round trips, integer totals, per-currency overview, the missing-currency decode and the status cases, and `BillingDTOEditingTests` covers the editing helpers; no test references `BillingLimits` (the clamp ranges), the defaults or the settings keys, and `BillingRefusalText.repoAlreadyClaimed` is used only by the `FakeBillingClient` test double, so vectors billing-dt-os-009 to 013 have no direct test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
