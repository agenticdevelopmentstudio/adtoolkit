---
id: 55878D7D-97F1-420A-A732-680AC39C8FF4
title: "Expiring Memo"
domain: adtoolkit://cookbook/foundation/collections/expiring-memo
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A bounded per-key memo whose entries expire after a time-to-live and are computed outside the lock."
platforms:
  - swift
  - macos
tags:
  - foundation
  - collections
  - cache
  - memoization
depends-on: []
related:
  - adtoolkit://cookbook/foundation/collections/lru-cache
references: []
approved-by: ""
approved-date: ""
---

# Expiring Memo

## Overview

A thread-safe memo that computes a value once per key and reuses it until it is a configured time-to-live old. It is for a derived figure that is expensive to compute and barely moves, such as a walk over weeks of history that prints tenths of an hour, where a few minutes of staleness changes nothing a reader acts on. Unlike the least-recently-used cache, which bounds by count and never expires, this one expires, and it is bounded too, so a stream of new keys cannot grow it. A clock that goes backwards expires an entry at once, a compute that fails caches nothing, and the compute runs outside the lock so two callers that miss together both compute.

## Behavioral Requirements

- **constructor-contract**: The memo MUST be constructed with a time-to-live and a capacity, and MUST reject a capacity of zero or less as a programmer error.
- **serves-fresh-entry**: A lookup for a key MUST return the stored value without computing when the entry was stored strictly less than the time-to-live before the lookup time.
- **expires-at-ttl**: An entry that is exactly the time-to-live old, or older, MUST be recomputed and stored with the lookup time as its stored time.
- **clock-backwards-expires**: An entry stored later than the lookup time (a clock that went backwards) MUST be treated as expired and recomputed.
- **lookup-time-injectable**: The lookup time MUST be an optional parameter defaulting to the current time, so freshness is testable without waiting.
- **failed-compute-caches-nothing**: When the compute closure fails, the failure MUST propagate to the caller unchanged and no entry MUST be stored or changed.
- **compute-outside-lock**: The compute closure MUST run outside the memo's lock; two callers that miss the same key at the same time MAY both compute, and the last to finish stores its value.
- **sweep-on-store**: Storing a computed value MUST first discard every entry that is no longer fresh at the lookup time.
- **capacity-evicts-oldest**: After sweeping, when the key is not already held and the number of entries has reached the capacity, storing MUST drop the entry with the oldest stored time before inserting the new one.
- **count-includes-unswept**: The reported count MUST be the number of entries currently held, including entries that are stale but not yet swept.
- **remove-all**: The memo MUST offer a way to forget every entry.

## Appearance

Not applicable: The memo is not a visual component.

## States

Not applicable: The memo is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The memo presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| expiring-memo-001 | serves-fresh-entry, expires-at-ttl | Memo with a 60-second time-to-live; read key `k` at t=0 (compute returns 1), at t=59, and at t=60 (compute returns 2). | t=0 returns 1; t=59 returns 1 without computing; t=60 computes and returns 2 (test: testServesTheStoredValueUntilItExpires). |
| expiring-memo-002 | clock-backwards-expires | Store key `k` at the start time, then read it one second before the start time with a compute returning 2. | Returns 2; the earlier entry was not trusted. |
| expiring-memo-003 | failed-compute-caches-nothing | Read key `k` with a compute that throws. | The error reaches the caller and the count stays 0. |
| expiring-memo-004 | capacity-evicts-oldest | Capacity 2; store keys `a`, `b`, `c` at increasing times, all still fresh. | The count is 2 and `a`, the oldest, is dropped; reading `a` computes again. |
| expiring-memo-005 | remove-all | Store two keys, then remove all. | The count is 0. |
| expiring-memo-006 | constructor-contract | Construct a memo with capacity 0. | Rejected as a programmer error. |
| expiring-memo-007 | sweep-on-store | Store `a`, advance past the time-to-live, then store `b`. | `a` is swept; the count is 1. |

## Edge Cases

- **Null / empty input**: Any hashable key, including an empty string, is accepted; a compute that returns an empty value is cached like any other.
- **Boundary values**: A time-to-live of zero or less makes every entry stale on the next lookup, so every call computes; a capacity of one holds a single entry and each new key replaces it. Freshness is strict: age equal to the time-to-live is stale.
- **Concurrent access**: All reads and writes of the table are serialized by one lock; the compute runs outside it, so concurrent misses for one key duplicate work rather than block. Callers that must be single-flight already are.
- **Error states**: A failing compute propagates and leaves the table unchanged (`failed-compute-caches-nothing`). The only programmer error is a non-positive capacity.
- **Offline / disconnected state**: Not applicable: The memo has no network access.
- **Cancellation**: Not applicable: The memo has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ttl | duration in seconds | none, required | How long an entry is served after it was stored. |
| capacity | positive integer | none, required | Keys held at once; storing past it drops the oldest. |

The memo reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The memo defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The memo contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The memo presents no UI.

## Feature Flags

Not applicable: The memo contains no feature-flag reference.

## Analytics

Not applicable: The memo contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The memo calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The class is `@unchecked Sendable` with an `NSLock`, and the compute parameter is `rethrows`.
- **Compose**: Use a `Mutex`-guarded `LinkedHashMap` or a Caffeine cache with `expireAfterWrite` and `maximumSize`; the clock-backwards rule needs an explicit stored-time comparison, which Caffeine's ticker does not give by default.
- **React/Web**: A `Map<Key, {storedAt, value}>` with a `now` parameter on `get(key, compute, now = Date.now())`. JavaScript is single-threaded, so no lock is needed, but an async compute needs an in-flight promise map if single-flight behavior is wanted.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use a `Dictionary<TKey, (DateTime StoredAt, TValue Value)>` guarded by a `lock` statement, with `GetOrCompute(key, compute, now)` running the compute outside the lock. `MemoryCache` with `AbsoluteExpirationRelativeToNow` and `SizeLimit` is the framework analog but does not expire on a backwards clock.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Collections/ExpiringMemo.swift` |

## Design Decisions

**Decision**: The compute runs outside the lock, so concurrent misses for one key both compute.
**Rationale**: Holding the lock across an arbitrary compute would serialize unrelated keys and risk deadlock when a compute re-enters the memo; the type's documentation accepts duplicate work because callers that need single-flight already are.
**Approved**: pending

**Decision**: Eviction and sweeping scan the whole table.
**Rationale**: The capacity is intended to be small, where a linear scan beats maintaining an ordered structure; the cost would only matter at capacities far beyond the intended use.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | passed | Performance |

`separation-of-concerns` passes because the type only memoizes by key with expiry; what is computed and when to ask are the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Collections/ExpiringMemoTests.swift` covers freshness at and past the time-to-live, a backwards clock, a throwing compute, capacity eviction and removal.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
