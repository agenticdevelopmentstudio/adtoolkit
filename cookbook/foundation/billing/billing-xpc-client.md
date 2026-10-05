---
id: 8055F7C9-D336-4B71-9F95-1BF4BDEF7B92
title: "Billing XPC Client"
domain: adtoolkit://cookbook/foundation/billing/billing-xpc-client
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The billing service interface and its transport-based client: typed reads and writes over a daemon, with refusals, unreachable and unreadable replies distinguished."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - client
  - xpc
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-xpc-protocol
  - adtoolkit://cookbook/foundation/billing/billing-model
  - adtoolkit://cookbook/foundation/billing/billing-dt-os
references: []
approved-by: ""
approved-date: ""
---

# Billing XPC Client

## Overview

Defines the service interface an app asks of billing (every read, write, count and the preferences push) and the client that implements it over a daemon connection. Reads answer nil when they failed, so a failed read is never an empty list. Writes answer the stored value or a refusal carrying the sentence the store gave. The client is generic over a small transport interface (decoded calls, refusable calls, int and data calls) so any transport, including a test double, can stand in, and so this tier depends on no daemon framework. Bodies are encoded snake_case and replies decoded snake_case with ISO-8601 dates.

## Behavioral Requirements

- **failed-read-is-nil**: A list read MUST return nil when the transport fails or when any element is the read-failed sentinel row; it MUST NOT return an empty list for a failure.
- **write-result**: A write MUST return the decoded stored value on success, a refusal carrying the store's sentence when the daemon refused, `unreachable` when the call threw, and `unreadable` when the reply or the body could not be coded.
- **refusal-fallback**: A refusal with no reason MUST read "The daemon refused the change."
- **write-timeout**: Writes MUST wait 65 seconds, longer than the daemon's own 60-second write bound, and MUST NOT be retried.
- **delete-result**: A delete MUST return success, a refusal with the daemon's sentence, or `unreachable`.
- **count-result**: A count call MUST return nil when the transport fails or the count is negative (the failed-count sentinel), and the count otherwise, so zero means nothing to do.
- **overview-read**: `billingOverview` MUST return nil on any failure.
- **preferences-push**: `billingSetPreferences` MUST send the body with a 5-second timeout and no retry, and MUST return true only when the reply is non-empty.
- **default-preferences**: A service that does not implement the push MUST report every push as not applied.
- **wire-coding**: Bodies MUST be encoded with snake_case keys; replies MUST be decoded with snake_case keys and ISO-8601 dates, by one shared decoder.
- **transport-seam**: The client MUST depend only on the transport interface, not on a daemon framework.
- **entry-filters**: `billingEntries` MUST send nil filters as "any", a status as its raw string, and `since` as an ISO day.

## Appearance

Not applicable — this is a non-visual service client, not a visual component.

## States

Not applicable — this is a non-visual service client, not a visual component.

## Accessibility

Not applicable — this is a non-visual service client, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-xpc-client-001 | failed-read-is-nil | list reply contains the read-failed row | nil |
| billing-xpc-client-002 | failed-read-is-nil | transport throws | nil |
| billing-xpc-client-003 | write-result | daemon returns the stored client JSON | `.success(client)` |
| billing-xpc-client-004 | write-result | daemon refuses with "A name is required." | `.failure` whose message is that sentence |
| billing-xpc-client-005 | write-result | transport throws | `.failure(.unreachable)` ("The daemon isn't answering.") |
| billing-xpc-client-006 | write-result | reply is not valid JSON for the type | `.failure(.unreadable)` |
| billing-xpc-client-007 | refusal-fallback | refusal with nil reason | message "The daemon refused the change." |
| billing-xpc-client-008 | write-timeout | any write | timeout 65 s, retries 0 |
| billing-xpc-client-009 | count-result | reply -1 | nil |
| billing-xpc-client-010 | count-result | reply 0 | 0 |
| billing-xpc-client-011 | preferences-push | reply empty data | false |
| billing-xpc-client-012 | preferences-push | reply non-empty data | true |
| billing-xpc-client-013 | wire-coding | reply with `started_at` and an ISO-8601 date | decoded to `startedAt` and a date |

## Edge Cases

- A body that cannot be encoded never leaves the process.
- A read that times out is treated as nil, indistinguishable from other failures.
- A write sent but not answered within the bound may still commit on the daemon; the bound exists to make that rare.
- The overview and the preferences push have their own failure shapes (nil and false), not refusals.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| transport | billing XPC transport | required | Answers the six call shapes. |
| writeTimeout | seconds | 65 | Wait for a write's answer. |

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

The fallback refusal sentences ("The daemon isn't answering.", "The daemon's reply couldn't be read.", "The daemon refused the change.") are hardcoded English strings.

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

- **SwiftUI**: Not used; the client has no view layer.
- **Compose**: A repository over Retrofit or a bound service, returning a sealed result.
- **React/Web**: A client over `fetch` with a typed `Result`; JSON snake_case in and out.
- **AppKit / UIKit**: Generic `final class BillingXPCClient<Transport: BillingXPCTransport>: BillingService`; the leaf adds the retroactive transport conformance to its XPC client.
- **WinUI 3**: A client over `HttpClient` or a named-pipe/RPC transport with `System.Text.Json` (`JsonNamingPolicy.SnakeCaseLower`), returning a `Result<T, BillingRefusal>`; the daemon connection is not XPC on Windows.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingXPCClient.swift` |

## Design Decisions

**Decision**: Timeouts and decode failures on reads collapse into one nil.
**Rationale**: The caller only needs "could not read"; distinguishing the causes would need an error type on every read.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. unit-test-coverage is partial: `BillingXPCClientTests` covers the write bound and no-retry, stored values, refusal sentences, unreachable and unreadable, read-failed rows, negative counts, the preferences push and the reply decoder. No test covers a failing list read (vector 002), a zero count (vector 010), a successful delete, `billingOverview`, the entry filters, the 5-second preferences timeout or the default preferences push.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
