---
id: FA95BD9D-DE48-4B37-8B30-748DC7B09280
title: "LRU Cache"
domain: adtoolkit://cookbook/foundation/collections/lru-cache
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A bounded, thread-safe key-value store that evicts the least recently used entry when an insert overflows."
platforms:
  - swift
  - macos
tags:
  - foundation
  - collections
  - cache
  - lru
depends-on: []
related:
  - adtoolkit://cookbook/foundation/collections/expiring-memo
references: []
approved-by: ""
approved-date: ""
---

# LRU Cache

## Overview

A bounded key-value store that forgets whatever was used longest ago. It is for state that is cheap to hold a few of and expensive to fetch again, such as the transcripts a reader is flicking between, where keeping every one ever seen would grow without limit and keeping none would refetch on every visit. Reads and writes are constant time; eviction scans for the stalest entry, linear in the capacity, and runs only when an insert overflows. At the capacities this is meant for (tens), that scan is cheaper than the linked list that would avoid it. All operations are serialized by one lock, so a background fetch can fill it while a foreground reader consults it.

## Behavioral Requirements

- **constructor-contract**: The cache MUST be constructed with a capacity and MUST reject a capacity of zero or less as a programmer error.
- **read-marks-used**: Reading a key MUST return its value, or nothing when absent, and when present MUST mark the entry as the most recently used.
- **set-marks-used**: Storing a value MUST make that entry the most recently used, replacing any existing value for the key.
- **overflow-evicts-lru**: When a store takes the number of entries above the capacity, the cache MUST remove exactly the least recently used entry.
- **overwrite-does-not-evict**: Overwriting an existing key MUST NOT evict any other entry.
- **peek-is-not-use**: A peek and a membership check MUST report on a key without counting as a use, so a caller deciding whether to refetch does not keep that entry alive.
- **remove-and-clear**: The cache MUST support removing one key (a no-op when absent) and removing all entries.
- **count-reported**: The cache MUST report the number of entries it holds, which never exceeds the capacity after any operation completes.
- **lock-guarded**: Every operation MUST be serialized by one lock so concurrent reads and writes from different threads never corrupt the table.

## Appearance

Not applicable: The cache is not a visual component.

## States

Not applicable: The cache is not a visual component; any runtime state it holds is described under Behavioral Requirements.

## Accessibility

Not applicable: The cache presents no UI.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| lru-cache-001 | read-marks-used | Capacity 2; store `a`=1, then read `a`, then read `b`. | Returns 1 for `a` and nothing for `b` (test: testStoresAndReturnsValues). |
| lru-cache-002 | overflow-evicts-lru | Capacity 2; store `a`, `b`, read `a`, store `c`. | `b` is evicted; `a` and `c` remain; count is 2 (test: testOverflowEvictsTheLeastRecentlyUsed). |
| lru-cache-003 | peek-is-not-use | Capacity 2; store `a`, `b`, peek `a`, store `c`. | `a` is evicted because the peek did not refresh it; `b` is still held. |
| lru-cache-004 | overwrite-does-not-evict | Capacity 2; store `a`=1, `b`=2, then store `a`=10. | Count is 2; `a` is 10 and `b` is 2 (test: testOverwritingAKeyDoesNotEvict). |
| lru-cache-005 | remove-and-clear | Remove key `a`, then remove all. | `a` is no longer held; the count is 0 (test: testRemoval). |
| lru-cache-006 | lock-guarded, count-reported | Hammer a capacity-16 cache with concurrent stores and reads from many threads. | The count never exceeds 16 (test: testConcurrentUseStaysWithinCapacity). |
| lru-cache-007 | constructor-contract | Construct a cache with capacity 0. | Rejected as a programmer error. |

## Edge Cases

- **Null / empty input**: Any hashable key, including an empty string, is valid; a stored value may itself be an empty value. A read of an absent key returns nothing and changes no order.
- **Boundary values**: Capacity one holds a single entry, and every new key evicts the previous one. Recency is a monotonically increasing counter that wraps rather than traps on overflow.
- **Concurrent access**: One lock guards the table and the counter; a read mutates recency, so even reads take the lock.
- **Error states**: No operation fails except the constructor on a non-positive capacity.
- **Offline / disconnected state**: Not applicable: The cache has no network access.
- **Cancellation**: Not applicable: The cache has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| capacity | positive integer | none, required | How many entries are kept before the least recently used one goes. |

The cache reads no environment variable or settings key of its own.

## Deep Linking

Not applicable: The cache defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The cache contains no user-facing string literal of its own.

## Accessibility Options

Not applicable: The cache presents no UI.

## Feature Flags

Not applicable: The cache contains no feature-flag reference.

## Analytics

Not applicable: The cache contains no analytics call.

## Privacy

- **Data handled**: Only the values its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value or instance the caller holds.

## Logging

Not applicable: The cache calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The class is `@unchecked Sendable` and uses an `NSLock`.
- **Compose**: Use a `LinkedHashMap(accessOrder = true)` with `removeEldestEntry`, or `android.util.LruCache`, behind a `synchronized` block; the peek and contains operations need a non-recording read.
- **React/Web**: A `Map` preserves insertion order, so delete-and-reinsert on read gives the same behavior in a few lines; JavaScript is single-threaded so no lock is needed.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A generic class over `Dictionary<TKey, Entry>` with a monotonic counter and a `lock` statement, or a `LinkedList` plus dictionary if capacities grow; `ConcurrentDictionary` alone is not enough because reads must update recency.

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/Core/Collections/LRUCache.swift` |

## Design Decisions

**Decision**: Eviction is a linear scan for the stalest entry rather than a linked list.
**Rationale**: The type's documentation reasons that at capacities in the tens the scan is cheaper than the pointer-chasing structure that would avoid it; a larger capacity would need an ordered structure, which is a contained change to this one type.
**Approved**: pending

**Decision**: Recency is a counter, not a timestamp.
**Rationale**: An incrementing counter orders uses exactly and cannot tie, which a clock could, and needs no time source.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | passed | Performance |

`separation-of-concerns` passes because the type only stores and evicts; what to cache and how to fetch are the caller's. `unit-test-coverage` passes because `AgenticToolkitCoreTests/Collections/LRUCacheTests.swift` covers store and read, least-recently-used eviction, peek not counting as a use, overwrite, removal and concurrent use within capacity.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
