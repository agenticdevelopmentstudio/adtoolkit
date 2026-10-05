---
id: 37DFDD98-266A-4253-8F0A-42987017844A
title: "Billing Activity Cache"
domain: adtoolkit://cookbook/foundation/billing/billing-activity-cache
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An in-memory, bounded cache of each live session's activity instants and event cursor, so a billing pass reads only new events."
platforms:
  - swift
  - macos
tags:
  - billing
  - foundation
  - cache
depends-on: []
related:
  - adtoolkit://cookbook/foundation/billing/billing-persistence
  - adtoolkit://cookbook/foundation/billing/billing-derivation
  - adtoolkit://cookbook/foundation/billing/billing-store
references: []
approved-by: ""
approved-date: ""
---

# Billing Activity Cache

## Overview

Derivation is a pure function over a session's whole activity history, but re-reading that history from the event store every pass is unaffordable for long sessions. This cache keeps, per session, the parsed history (sorted, de-duplicated epoch seconds) and the event-row cursor it was read up to. Each pass reads only the tail past the cursor, merges it in, and hands the full history to derivation. The cache is in memory only: after a restart the first pass per session reads in full once, and nothing on disk can drift out of step with the event store. It is shared by every copy of the billing task, so it is a reference type, and its bounding and locking are those of the shared LRU cache.

## Behavioral Requirements

- **activity-seconds**: `activitySeconds(sessionId, database)` MUST return the session's full history as ascending, unique epoch seconds, reading from the persistence layer only events with an id greater than the cached cursor (zero when uncached).
- **cursor-advance**: After a read, the cache MUST store the returned `lastId` as the new cursor together with the merged history.
- **merge-sorted-unique**: `merging(fresh, into: sorted)` MUST return an ascending, duplicate-free list containing every value of both inputs; `fresh` may be unordered and repeat.
- **merge-append-fast-path**: When every incoming value is later than the last held value, the merge MUST append rather than re-sort.
- **merge-empty-fresh**: An empty `fresh` MUST return `sorted` unchanged.
- **forget**: `forget(sessionId)` MUST drop the session's entry; it is called once the session has ended.
- **bounded**: The cache MUST hold at most `capacity` sessions (default 64) and evict the least recently used entry beyond that; an evicted session costs one full read if it returns.
- **read-error-propagates**: An error thrown by the persistence read MUST propagate to the caller and MUST leave the cached entry unchanged.
- **in-memory-only**: The cache MUST NOT persist anything to disk.

## Appearance

Not applicable — this is a non-visual in-memory cache, not a visual component.

## States

Not applicable — this is a non-visual in-memory cache, not a visual component.

## Accessibility

Not applicable — this is a non-visual in-memory cache, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-activity-cache-001 | merge-append-fast-path | `merging([30, 20], into: [10])` | `[10, 20, 30]` |
| billing-activity-cache-002 | merge-sorted-unique | `merging([5, 15, 15], into: [10, 20])` | `[5, 10, 15, 20]` |
| billing-activity-cache-003 | merge-sorted-unique | `merging([10, 20], into: [10, 20])` | `[10, 20]` |
| billing-activity-cache-004 | merge-empty-fresh | `merging([], into: [1, 2])` | `[1, 2]` |
| billing-activity-cache-005 | merge-sorted-unique | `merging([3, 1, 2], into: [])` | `[1, 2, 3]` |
| billing-activity-cache-006 | cursor-advance | first call reads after id 0 and returns lastId 40; second call | reads after id 40 |
| billing-activity-cache-007 | forget | call, `forget`, call again | second call reads after id 0 |
| billing-activity-cache-008 | bounded | 65 distinct sessions with capacity 64 | `count` is 64; the first session was evicted |

## Edge Cases

- A session with no events returns an empty history and stores cursor from the read result.
- An event stored with an earlier timestamp than held values is merged in order, not appended.
- Concurrent calls for different sessions are safe because the underlying cache is locked; two concurrent calls for the same session may both read the same tail and merge identically.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| capacity | integer | 64 | Sessions held at once (`defaultCapacity`). |

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

- **SwiftUI**: Not used; the cache has no view layer.
- **Compose**: A `LinkedHashMap` with `removeEldestEntry` behind a `Mutex`, with a `LongArray` of seconds per entry.
- **React/Web**: A `Map` used as an LRU (delete and re-insert on read); single-threaded, so no lock.
- **AppKit / UIKit**: A `final class` marked `Sendable`, delegating to `LRUCache<String, Entry>` with a private `Entry { cursor: Int64; seconds: [Int] }`.
- **WinUI 3**: A `ConcurrentDictionary` plus a lock-guarded recency list, or `MemoryCache` with a size limit; use `SortedSet<int>` or the same merge over `List<int>`.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Billing/BillingActivityCache.swift` |

## Design Decisions

**Decision**: No test exercises the cache or `merging` directly.
**Rationale**: The behavior is exercised only through the billing store's passes; a unit test of `merging` (pure) and of cursor handling with a stub persistence is the gap to close.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: the cache owns only history merging and cursor bookkeeping; eviction and locking are delegated to the shared LRU cache and the read to the persistence protocol. unit-test-coverage fails: a search of the Tests directories finds no test that references the cache or `merging`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
