---
id: 36C76E0F-B41C-4FD6-A349-A0E9241FB489
title: "Billing XPC Protocol"
domain: adtoolkit://cookbook/foundation/billing/billing-xpc-protocol
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Objective-C protocol a daemon exports for billing: every selector, its JSON-data payloads, and the reply conventions for refusals and failures."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - xpc
  - wire
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-xpc-client
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing XPC Protocol

## Overview

The billing half of a daemon's XPC surface as its own protocol, so any app (a menu-bar app, a command-line tool) can talk billing to a daemon without linking the daemon's whole protocol. A daemon declares a composite protocol refining both its own and this one; a client builds its interface from this one alone. NSXPC dispatches by selector, so both sides agree as long as these selectors do not change. Every payload crosses as JSON data (snake_case, ISO-8601) because the transport only carries property-list types. The reply conventions carry meaning: a nil or false write reply means nothing was written and the second argument gives the reason; a list read that failed is the single sentinel row; a count of -1 means the write failed.

## Behavioral Requirements

- **json-payloads**: Every DTO MUST cross as JSON data, snake_case keys and ISO-8601 dates.
- **write-reply-shape**: A write reply MUST be a stored-value payload (or true) plus an optional refusal sentence; a nil or false first value MUST mean nothing was written and the sentence MUST say why; the sentence MUST be nil on success.
- **list-read-failure**: A list read that failed MUST reply with the one element `BillingWire.readFailedRow`, never an empty list.
- **count-failure**: A count reply MUST be `BillingWire.failedCount` (-1) when the write threw, never 0, which means nothing to do.
- **clients-projects**: Client and project reads MUST include archived records so archived history still names its owner; deleting a client MUST detach its projects and deleting a project MUST detach its segments, never delete them.
- **entries-read**: Entries MUST be newest day first; nil `projectId`, `status` and `since` mean any; `since` is an ISO day.
- **entry-writes**: `billingSaveEntry` MUST be refused when the entry is billed or paid; `billingSetEntryStatus` MUST write an audit row and reply nil for an unknown id or status; `billingSetEntryDescription` MUST change only the description; `billingDeleteEntry` MUST reply false when the entry is locked or unknown.
- **audit-read**: `billingEntryAudit` MUST return the trail oldest first.
- **segments-read**: `billingSegments` MUST return recorded time newest first, from an ISO-8601 `since` and up to `limit`.
- **timers**: `billingStartTimer` MUST stop any other running timer first; `billingStopTimer` MUST reply the closed segment.
- **assignment**: `billingAssignSegments` and `billingAssignRepository` MUST reply how many moved; `billingPromoteSegments` how many entries were written; `billingBackfill` how many sessions were queued.
- **overview**: `billingOverview` MUST reply one encoded overview payload.
- **set-preferences**: `billingSetPreferences` MUST apply the eight knobs, reply the clamped snapshot now in force, and reply empty data when the write failed.
- **selectors-stable**: Selector names MUST NOT change, because the two sides agree by selector.

## Appearance

Not applicable — this is a wire protocol declaration, not a visual component.

## States

Not applicable — this is a wire protocol declaration, not a visual component.

## Accessibility

Not applicable — this is a wire protocol declaration, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-xpc-protocol-001 | write-reply-shape | save of a client with an empty name | first reply nil; second "A name is required." |
| billing-xpc-protocol-002 | write-reply-shape | successful client save | first reply the stored client JSON; second nil |
| billing-xpc-protocol-003 | list-read-failure | clients read fails | one element: the read-failed row |
| billing-xpc-protocol-004 | count-failure | assign throws | reply -1 |
| billing-xpc-protocol-005 | count-failure | assign finds nothing to move | reply 0 |
| billing-xpc-protocol-006 | entry-writes | save of a billed entry | nil reply with a sentence |
| billing-xpc-protocol-007 | entry-writes | delete of a locked entry | false reply with a sentence |
| billing-xpc-protocol-008 | clients-projects | client read when one is archived | archived client included |
| billing-xpc-protocol-009 | set-preferences | push of an idle cutoff of 9999 minutes | reply carries the clamped 480 |
| billing-xpc-protocol-010 | set-preferences | write failed | empty data reply |
| billing-xpc-protocol-011 | timers | start while another timer runs | the other is closed first |

## Edge Cases

- A decoder that cannot read a body yields the nil-with-reason write reply, never a crash.
- A DTO per selector is deliberately avoided: it would need a secure-coding class per DTO.
- The protocol declares only billing; a daemon's other selectors live in its own protocol.

## Configuration

None: a wire protocol declaration takes no configuration beyond the values passed to each call.

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

Payloads carry client names, contacts, rates and hours between the app and its own local daemon over a same-user XPC connection; nothing leaves the machine through this protocol.

## Logging

Not applicable: this code makes no log calls.

## Platform Notes

- **SwiftUI**: Not used; the protocol has no view layer.
- **Compose**: An AIDL interface or a gRPC service definition with the same operation set.
- **React/Web**: A JSON-RPC or REST API: one route per selector with the same body, refusal and sentinel conventions.
- **AppKit / UIKit**: An `@objc` protocol with `reply:` closures, exported by an `NSXPCListener` and consumed by an `NSXPCConnection` interface built from this protocol.
- **WinUI 3**: A named-pipe or localhost HTTP API with `System.Text.Json`; `BillingWire.failedCount` and the read-failed row carry over unchanged.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingXPCProtocol.swift` |

## Design Decisions

**Decision**: The protocol is a wire declaration with no enforcement.
**Rationale**: Conformance of a daemon is not checked at compile time against the reply conventions in the comments; a shared conformance test would enforce them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: the protocol is a pure wire declaration kept apart from any daemon's own surface and from the client. unit-test-coverage is partial: `BillingXPCClientTests` exercises the client's reading of the reply conventions and the decoder, but no shared test asserts that a daemon implementing the protocol honors them.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
