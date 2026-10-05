---
id: 359A896F-ECC0-45D7-991A-B4FBC24C9511
title: "Billing Editing"
domain: adtoolkit://cookbook/foundation/billing/billing-editing
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Copy-with-changes edits for the immutable billing records, repricing, rate-text parsing and record titles."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - editing
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
  - adtoolkit://cookbook/foundation/billing/billing-rate
references: []
approved-by: ""
approved-date: ""
---

# Billing Editing

## Overview

The billing records (client, project, repo, entry) are immutable, so an edit is a copy with some fields changed. This component supplies those copies, the hand-edit repricing that keeps an entry's amount consistent with the rollup arithmetic, validated parsing of a typed hourly rate, and the display titles used by lists and choosers: a placeholder for a blank name and disambiguated project labels. The creation and update stamps belong to the daemon and are never offered for editing.

## Behavioral Requirements

- **replacing-keeps-unnamed**: Each `replacing` copy MUST keep every field whose argument is omitted.
- **replacing-clears-nullable**: Nullable fields (project client, default rate, repo rate) MUST accept an explicit absent value that clears the field, distinct from omission.
- **stamps-untouched**: `createdAt` and `updatedAt` MUST be carried over unchanged; identity fields not offered (an entry's project, client, group key, raw seconds, currency, rounding, status, origin, lock) MUST NOT change.
- **repriced-amount**: `repriced(billedSeconds:rateCents:)` MUST set the billed seconds and rate and recompute the amount with the same money arithmetic the rollup uses; raw seconds MUST stay as tracked.
- **rate-parse**: `billingRate(parsing:)` MUST trim whitespace, parse the text as money into cents, and return nil if it is not a number or is outside the allowed default-rate range (0 to 10,000,000 cents).
- **rate-one-rule**: Every rate field MUST take its text through `billingRate(parsing:)` so all refuse the same input.
- **title-fallback**: `BillingRecordTitle.of(name)` MUST return the trimmed name, or `Untitled` when it is blank.
- **labels-disambiguate**: `projectLabels` MUST return a label per project id; a name two projects share MUST be followed by its client name (`No Client` when none), and by the first six characters of the id if the label still repeats.
- **labels-unique-first**: If two clients or two projects share an id, the first one listed MUST supply the name used for that id.

## Appearance

Not applicable — this is a set of pure record helpers, not a visual component.

## States

Not applicable — this is a set of pure record helpers, not a visual component.

## Accessibility

Not applicable — this is a set of pure record helpers, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-editing-001 | replacing-keeps-unnamed | client `replacing(name: "New")` | only the name differs |
| billing-editing-002 | replacing-clears-nullable | project with a rate, `replacing(defaultRateCents: .some(nil))` | rate is nil |
| billing-editing-003 | replacing-clears-nullable | same project, `replacing()` | rate unchanged |
| billing-editing-004 | repriced-amount | entry 3000 raw seconds, `repriced(billedSeconds: 5400, rateCents: 12000)` | amount 18000 cents; raw seconds 3000 |
| billing-editing-005 | rate-parse | `" 150.00 "` | 15000 |
| billing-editing-006 | rate-parse | `"abc"` | nil |
| billing-editing-007 | rate-parse | a value above 100,000.00 | nil |
| billing-editing-008 | title-fallback | `"Acme"` then `"  "` | `Acme` then `Untitled` |
| billing-editing-009 | labels-disambiguate | projects Site (Acme), Site (Beta), Site (Beta, other id), Other (no client) | `Site — Acme`, `Site — Beta — p2bbbb`, `Site — Beta — p3cccc`, `Other` |

## Edge Cases

- A blank name never produces an empty label.
- A project whose client id is unknown reads as `No Client` when it must be told apart.
- Negative or non-numeric rate text is refused rather than clamped.
- Editing a locked entry is not refused by these copies; they only build the changed record.

## Configuration

None: a set of pure record helpers takes no configuration beyond the values passed to each call.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

The placeholder `Untitled`, the fallback `No Client` and the label separator are hardcoded English strings; they are not routed through a string catalog.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Labels feed `Picker` and list rows; no SwiftUI types appear here.
- **Compose**: Data class `copy(...)` with a nullable-wrapper (`Optional<T>`) for clearable fields.
- **React/Web**: Spread-copy (`{...record, ...changes}`) with `null` as the clear value.
- **AppKit / UIKit**: Extensions on the immutable DTOs; the double-optional `Int??` distinguishes omit from clear.
- **WinUI 3**: C# `record` types with `with` expressions; `decimal.TryParse` with `CultureInfo.CurrentCulture` for rate text, then convert to cents.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingEditing.swift` |

## Design Decisions

**Decision**: Blank and placeholder names are not localized.
**Rationale**: `Untitled`, `No Client` and the label separator are fixed English strings in the source; localizing them would route them through the string catalog.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: edits, repricing and titles are pure helpers; money arithmetic and rate parsing are the shared money utilities and the daemon owns the stamps. unit-test-coverage is partial: `BillingDTOEditingTests` covers `replacing`, clearing, `repriced` and the record titles and labels, but no test asserts the rate-text parsing range.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
