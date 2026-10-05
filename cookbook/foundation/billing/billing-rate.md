---
id: BBE7358F-2001-4E67-83CB-0627DE522C42
title: "Billing Rate"
domain: adtoolkit://cookbook/foundation/billing/billing-rate
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The rate-resolution ladder: which project claims a repo and branch, and which hourly rate applies."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - rate
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-rollup
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing Rate

## Overview

Two pure functions that decide who claims a stretch of work and what rate it bills at. `resolve` maps a project root and branch to a claim (a repo row and a project, or Unassigned). `rateCents` walks the rate ladder for a segment that already knows its repo row. The ladder, most specific first: the repo row matching the root and branch, the repo row matching the root with an empty branch, the project default rate, then the global default rate from settings. The first non-null rate wins, and a rate of zero is a real rate.

## Behavioral Requirements

- **claim-exact-branch-first**: `resolve` MUST prefer the repo row whose project root and non-empty branch both match, then the repo row for the same root with an empty branch.
- **claim-unassigned**: If no repo row matches, `resolve` MUST return a claim with no repo and no project (the Unassigned bucket); the time is still tracked.
- **claim-missing-project**: If the matched repo row points at a project that does not exist, the claim MUST carry the repo but no project.
- **claim-ignores-billing-flag**: `resolve` MUST NOT consider whether billing is enabled; a repo with billing off still claims the work.
- **rate-ladder**: `rateCents` MUST return the first non-null of: the repo row's rate, the any-branch row's rate for the same root (only when the repo row has a branch), the project's default rate, the global default.
- **rate-zero-is-a-rate**: A zero rate MUST be treated as a rate, not as absence.
- **rate-no-repo**: With no repo row (a hand-assigned or manual segment), `rateCents` MUST fall to the project default, then the global default.
- **shared-ladder**: The rollup MUST use `rateCents` so the claim and the rate cannot disagree.

## Appearance

Not applicable — this is a pure resolution function, not a visual component.

## States

Not applicable — this is a pure resolution function, not a visual component.

## Accessibility

Not applicable — this is a pure resolution function, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rate-001 | claim-exact-branch-first | rows r1 (`/app`, any branch, 9000) and r2 (`/app`, `rush`, 20000); root `/app`, branch `rush` | repo r2, rate 20000 |
| billing-rate-002 | claim-exact-branch-first | same rows; branch `main` | repo r1, rate 9000 |
| billing-rate-003 | rate-ladder | repo with no rate, project default 10000 | 10000 |
| billing-rate-004 | rate-ladder | repo with no rate, project with no default, global 5000 | 5000 |
| billing-rate-005 | rate-ladder | branch row `rush` with no rate, any-branch row with 9000, project default 10000 | 9000 |
| billing-rate-006 | claim-unassigned | root `/elsewhere`, no repos | no repo, no project |
| billing-rate-007 | claim-ignores-billing-flag | repo r1 with billing disabled | project p1, repo r1 |
| billing-rate-008 | rate-zero-is-a-rate | repo rate 0 | 0 |
| billing-rate-009 | claim-missing-project | repo pointing at project `gone`, global 5000 | no project, rate 5000 |

## Edge Cases

- An empty branch argument matches only the any-branch row, never an exact-branch row.
- Several rows with the same root and branch: the first in list order wins.
- An empty repo list yields Unassigned.

## Configuration

None: a pure resolution function takes no configuration beyond the values passed to each call.

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

Not applicable: this code collects, stores and transmits nothing of its own.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the type has no view layer.
- **Compose**: A pure function over data classes; `firstOrNull` replaces `first(where:)`.
- **React/Web**: A pure function over plain objects; `Array.prototype.find` replaces `first(where:)`.
- **AppKit / UIKit**: Plain Swift over `BillingRepoDTO` and `BillingProjectDTO`; results are `Sendable` and `Equatable`.
- **WinUI 3**: Static methods over record types; use `FirstOrDefault` with a null check and `int?` for nullable cents.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingRate.swift` |

## Design Decisions

**Decision**: Duplicate repo rows for one root and branch resolve to the first in list order.
**Rationale**: The resolver reads whatever rows it is given and does not check uniqueness; the billing store's repo save refuses a second claim on the same root and branch and the host's unique index backstops it, so duplicates should not reach this layer, and if they do the first row wins.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: only claim and rate resolution live here; enabled-ness is the store's decision and the rate is shared with the rollup. unit-test-coverage passes: `BillingRateResolutionTests` covers branch precedence, rate inheritance, Unassigned, billing-off claims, zero rate, missing project and the any-branch step.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
