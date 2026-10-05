---
id: 7B3E5D12-9A64-4C0F-8E21-5F1D6A7C3B90
title: "UseTablesWithRows"
domain: adtoolkit://cookbook/ui/crud/use-tables-with-rows
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Has-rows sweep from @agentic-toolkit/crud: probes each candidate table with a limit-one list, sorts tables into populated, empty and unknown, and remembers the answer per user, filter, scope and table set."
platforms:
  - typescript
  - web
tags:
  - crud
  - data-browser
  - probe
  - cache
depends-on: []
related:
  - adtoolkit://cookbook/ui/crud/crud-table
references: []
approved-by: ""
approved-date: ""
---

# UseTablesWithRows

## Overview

`useTablesWithRows` in `@agentic-toolkit/crud` answers one question for a
data browser's table rail: **which of these tables hold at least one row**,
for the open filter and scope. It is a state-and-network operation with no
visual surface of its own; the `CrudDataBrowser` rail consumes its answer to
list populated tables, set empty ones apart, and mark tables it could not check.

For each candidate table it sends that table's own list request with a
`limit=1` parameter, using the same filter and ecosystem scope the open view
would send, so "has data" is answered by exactly the authorization and scoping
that would serve the rows. It runs the probes with bounded concurrency,
reports the result as three disjoint key sets (`populated`, `empty`,
`unknown`) plus a `failed` flag, and remembers each finished answer so a
remount does not sweep again.

## Behavioral Requirements

- **disable-on-null-filter**: When `filter` is `null`, the operation MUST NOT
  send any probe and MUST return the pending answer: `populated`, `empty` and
  `unknown` all `null`, `failed` false and `firstWithRows` `null`.
- **probe-with-limit-one-list**: For each candidate table the operation MUST
  send that table's own list request, built by `listUrl` from the table, the
  filter and `scopeEcosystemId`, with `limit=1` appended (as `&limit=1` when
  the URL already carries a query string, otherwise `?limit=1`).
- **populated-when-row-found**: A probe that answers with a non-empty array
  MUST put the table's `key` in `populated`.
- **empty-when-no-rows**: A probe that answers with an empty array, or with a
  value that is not an array, MUST put the table's `key` in `empty`.
- **forbidden-or-missing-in-no-set**: A probe refused with HTTP 403 or 404
  MUST leave the table's `key` in none of the three sets, because a table this
  viewer cannot list has nothing to offer them.
- **unknown-on-other-failure**: A probe that fails for any other reason (a 5xx,
  a 429, a dropped connection) MUST put the table's `key` in `unknown` and MUST
  make the completed answer's `failed` true; such a failure is "could not
  check", never "empty".
- **bounded-concurrency**: The operation MUST keep at most 8 probes in flight
  at once (`PROBE_CONCURRENCY`).
- **probe-first-table-first**: When `first` names a candidate, the operation
  MUST move that table to the head of the probe queue.
- **report-first-with-rows-early**: While no answer is on screen and the sweep
  is still running, the operation MUST report `firstWithRows` as the `first`
  table's key as soon as its probe finds a row, with the three sets still
  `null`, so the open table can mount before the sweep finishes. `firstWithRows`
  MUST be `null` in every finished answer, and MUST NOT be reported over a
  remembered answer.
- **cache-by-principal-filter-scope-tables**: The operation MUST remember each
  successful, complete answer under a key made of the asking principal (the
  `principal` option, falling back to the signed-in token's subject), the
  filter, `scopeEcosystemId`, and the candidate table keys joined in order. The
  remembered answers MUST be held at module scope so they survive a remount.
- **serve-fresh-answer-without-sweeping**: A remembered answer younger than
  `TABLES_WITH_ROWS_TTL_MS` (60 000 ms) MUST be returned from the first render
  and MUST NOT trigger a sweep.
- **revalidate-stale-answer**: A remembered answer older than that window MUST
  be returned at once and a sweep MUST run behind it, replacing it when the
  sweep finishes.
- **keep-answer-when-revalidation-fails**: When a revalidating sweep ends with
  any `unknown` table, the operation MUST keep the remembered answer on screen
  rather than replace it with the partial one.
- **never-remember-failed-sweep**: A sweep whose answer has `failed` true
  MUST NOT be stored, so the next mount asks again.
- **clear-on-principal-change**: The operation MUST drop every remembered
  answer when the signed-in principal changes (observed through the session
  change notification and the cross-tab storage event) and MUST NOT let a sweep
  that began before the change store its answer.
- **abort-on-leave**: When the operation's inputs change or its owner goes
  away mid-sweep, it MUST abort the probes in flight and drop the queued ones.
- **reset-for-tests**: `resetTablesWithRows()` MUST empty every remembered
  answer and invalidate any sweep already running.

Returned shape (`TablesWithRows`): `populated` and `empty` and `unknown` are
sets of table keys, or all `null` together while the answer is still coming;
`failed` is true when some probe was `unknown`; `firstWithRows` is a table key
or `null`.

## Appearance

Not applicable — this is a data operation, not a visual component.

## States

Not applicable — this is a data operation, not a visual component. Its runtime
states are pending (all sets `null`), early-first (`firstWithRows` set, sets
still `null`), remembered-fresh, remembered-revalidating and complete, covered
under Behavioral Requirements.

## Accessibility

Not applicable — this is a data operation, not a visual component.

## Conformance Test Vectors

The sweep is exercised through `CrudDataBrowser` in
`packages/web/packages/crud/src/__tests__/CrudDataBrowser.workspace.test.tsx`;
each vector names the test that pins it where one exists.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| use-tables-with-rows-001 | disable-on-null-filter | `filter = null`, any tables | No request is sent; the result is the pending answer (three sets `null`, `failed` false, `firstWithRows` `null`) |
| use-tables-with-rows-002 | probe-with-limit-one-list, populated-when-row-found, empty-when-no-rows | Two tables; the first probe answers one row, the second answers `[]` | Both probes are the table's list URL with `limit=1`; `populated` holds the first key, `empty` the second, `unknown` is empty and `failed` is false (`sets tables with no rows, and a schema left with none, apart in an Empty group`) |
| use-tables-with-rows-003 | forbidden-or-missing-in-no-set | A table's probe answers 403, another's answers 404 | Neither key is in any of the three sets; `failed` is false (`counts a 403 or a 404 as no rows`) |
| use-tables-with-rows-004 | unknown-on-other-failure | A table's probe answers 500 | The key is in `unknown` and `failed` is true (`lists every table it couldn’t check, marked so, not "No data yet."`) |
| use-tables-with-rows-005 | bounded-concurrency | 20 candidate tables whose probes stay pending | No more than 8 probes are outstanding at any moment |
| use-tables-with-rows-006 | probe-first-table-first, report-first-with-rows-early | `first` names the fifth table; its probe answers a row while the rest are pending | The fifth table is probed first; `firstWithRows` is its key while the three sets are still `null` (`opens the open table on its own probe, without waiting on the rest`) |
| use-tables-with-rows-007 | serve-fresh-answer-without-sweeping | A finished sweep, then a remount with the same principal, filter, scope and tables within 60 s | The remembered answer is returned on the first render and no probe is sent (`serves a fresh remembered answer on a remount without probing again`) |
| use-tables-with-rows-008 | revalidate-stale-answer | Same remount after more than 60 s | The remembered answer is returned at once and probes run behind it (`shows a stale remembered answer on a remount at once, then asks again quietly`) |
| use-tables-with-rows-009 | keep-answer-when-revalidation-fails, never-remember-failed-sweep | A stale remembered answer; the revalidating sweep has a 500 | The remembered answer stays on screen; after a failed first sweep, a later mount probes again (`keeps the remembered answer when asking again fails`, `asks again after a sweep that failed`) |
| use-tables-with-rows-010 | cache-by-principal-filter-scope-tables, clear-on-principal-change | One user's remembered answer; a different principal mounts, or the signed-in subject changes | The other user is never served it; after the change every remembered answer is gone (`never serves one user’s remembered answer to another`, `forgets every answer when someone else signs in`) |
| use-tables-with-rows-011 | abort-on-leave | Unmount mid-sweep with probes in flight and others queued | In-flight probes are aborted and none of the queued probes is sent (`aborts the probes in flight on unmount, and sends none of the queued ones`) |

## Edge Cases

- Empty candidate list: the sweep sends no probes and completes with three empty
  sets and `failed` false.
- A probe that answers with something other than an array is treated as no
  rows (`empty`), not as a failure.
- All probes failing leaves `populated` empty and `unknown` holding every
  table, with `failed` true; the caller can tell "could not check" from "no
  data".
- A revalidating sweep that sees a table gain its first row replaces the
  remembered answer when it finishes; until then the stale answer shows.
- Two principals sharing a workspace slug or ecosystem id never share an
  answer: the principal is part of the key, and a principal change clears the
  store.
- Under a development double-mount, the first mount's sweep is aborted so
  probes never exceed the concurrency bound.
- The cancellation of an aborted probe is swallowed: it lands in the failure
  path but its result is never read because the sweep is no longer live.
- Concurrent access: the operation is confined to a single-threaded event loop;
  probes overlap only as in-flight network requests, bounded by
  `PROBE_CONCURRENCY`.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `tables` | `CrudTableMeta[]` | none — required | Candidate tables to probe; identified by their `key`, in order. |
| `filter` | `Record<string, string> \| null` | none — required | Filter every probe sends; `null` disables the sweep. |
| `scopeEcosystemId` | `string` | omitted | The open view's ecosystem scope, so each probe is the list the view would send. |
| `first` | `string \| null` | `null` | Key of the open table; probed ahead of the rest and reported early. |
| `principal` | `string \| null` | the token's subject | Who is asking; part of the cache key. |
| `TABLES_WITH_ROWS_TTL_MS` | exported constant | 60 000 | How long a remembered answer counts as fresh. |
| `PROBE_CONCURRENCY` | internal constant | 8 | Maximum probes in flight. |

Callers derive `tables` and `filter` anew each render; the operation compares
content signatures (the joined table keys and the serialized filter), not
identities.

## Deep Linking

Not applicable: the operation defines no URL scheme or route; it only reads the open view's filter and scope that the caller passes in.

## Localization

Not applicable: the operation contains no user-facing string; its result is sets of table keys and a flag.

## Accessibility Options

Not applicable: the operation presents no UI and so has no motion, contrast or text-size behavior.

## Feature Flags

Not applicable: the operation contains no feature-flag or settings-key reference.

## Analytics

Not applicable: the operation contains no analytics or event-tracking call.

## Privacy

- **Data handled**: Table keys, the filter and ecosystem scope (identifiers such as a workspace slug or ecosystem id), and the signed-in principal's id used as a cache key. Probe responses are inspected only for being an empty or non-empty array; row contents are not read or retained.
- **Storage**: The remembered answers are held in module memory only; nothing is written to disk or browser storage.
- **Transmission**: One authenticated list request per candidate table, through the shared authenticated client; no other destination.
- **Retention**: A remembered answer lasts until the page reloads or the signed-in principal changes.

## Logging

Not applicable: the operation calls no logging API; failures are reported only through the `unknown` set and `failed` flag.

## Platform Notes

- **SwiftUI**: There is no source for Swift. Port the operation as an observable object (or an `actor` holding the cache) with an `async` sweep using a `TaskGroup` limited to 8 child tasks, `URLSession` data tasks carrying a cancellation-aware `URLRequest`, and `Task.checkCancellation` to stop on leave. Hold remembered answers in a process-wide actor keyed by the same principal, filter, scope and table-key string, with a `Date` stamp for the 60-second window, and clear it on the app's sign-in-changed notification.
- **Compose**: Port as a `ViewModel` exposing a `StateFlow<TablesWithRows>`; run the sweep in `viewModelScope` with a `Semaphore(8)` around `async` probes and cancel the `Job` on leave. Keep remembered answers in a singleton `ConcurrentHashMap` with `System.currentTimeMillis()` stamps, cleared when the auth session flow emits a new subject.
- **React/Web**: The source is `packages/web/packages/crud/src/useTablesWithRows.ts`, a `'use client'` React hook. State is a `useState` seeded from the module-level `answers` map; the sweep runs in a `useEffect` keyed on the joined signature, uses 8 worker loops draining a shared queue, `authedJson` from `@agentic-toolkit/auth/client` with an `AbortController` signal, and `AuthHttpError` to recognize 403 and 404. The session watcher binds `onSessionChange` and a `storage` event listener on first use, and a `generation` counter stops an overtaken sweep from writing its answer back.
- **AppKit / UIKit**: Same as the SwiftUI note: an `@MainActor` model object whose results update the table rail, with probes on `URLSession` and the cache in an `actor`. The sign-in-changed hook is the app's authentication notification rather than a `storage` event.
- **WinUI 3**: Port as a view-model class implementing `INotifyPropertyChanged`, exposing a `TablesWithRows` record of `HashSet<string>?` properties. Run the sweep with `Task.Run` and a `SemaphoreSlim(8)` bounding `HttpClient.GetAsync` probes, each given a `CancellationToken` from a `CancellationTokenSource` cancelled when the page navigates away, and treat `HttpStatusCode.Forbidden` and `NotFound` as the no-set case. Keep remembered answers in a static `ConcurrentDictionary<string, (TablesWithRows Answer, DateTimeOffset At)>` with a `Stopwatch` or `DateTimeOffset` freshness check, raise changes on the `DispatcherQueue`, and clear the dictionary from the app's auth-session-changed event, bumping an `Interlocked` generation counter so an overtaken sweep cannot store its answer.

## Reference Implementations

| Platform | Path |
|----------|------|
| web | `packages/web/packages/crud/src/useTablesWithRows.ts` |

## Design Decisions

**Decision**: Each probe is the table's own list request with `limit=1` rather than a separate counting endpoint.
**Rationale**: The source's own doc comment says "has data" is then answered by exactly the authorization and scoping that would serve the rows, "rather than by a second counting path that could disagree with it".
**Approved**: pending

**Decision**: A 403 or 404 puts a table in no set, while any other failure puts it in `unknown` and marks the sweep failed.
**Rationale**: Per the source's doc comment, counting every failure as empty hid tables that hold rows, and when every probe failed the rail said "No data yet." about a scope full of data; a refused or missing list says only that this viewer has nothing to see.
**Approved**: pending

**Decision**: Remembered answers live at module scope with a 60-second freshness window and are revalidated behind a stale answer rather than discarded.
**Rationale**: The source's comment explains that component state died with each remount, so every schema or table click swept dozens of probes again; never asking again kept a table that gained its first row out of the rail until reload, while always asking again swept on every click.
**Approved**: pending

**Decision**: A sweep that fails during revalidation leaves the remembered answer on screen, and no failed sweep is ever stored.
**Rationale**: A failed sweep is partial, so the last good answer is the better guess, and not storing it makes the next mount ask again, which is what the rail's "could not check" state asks of the viewer.
**Approved**: pending

**Decision**: The cache key includes the asking principal, and every answer is dropped when the signed-in principal changes.
**Rationale**: Keys such as a workspace slug or ecosystem id are shared by every member of that workspace, so without the principal the next person to sign in on a machine would be shown the previous one's rail; the subject is used rather than the raw token because a refresh writes a new token for the same user.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because `useTablesWithRows.ts` only decides which tables hold rows: URL construction is delegated to `listUrl`, the network call to `authedJson`, session identity to `readTokenSubject` and `onSessionChange`, and presentation to the `CrudDataBrowser` rail that consumes the result. `unit-test-coverage` is `partial`: the exported `resetTablesWithRows` and `TABLES_WITH_ROWS_TTL_MS` exist for tests, and `packages/web/packages/crud/src/__tests__/CrudDataBrowser.workspace.test.tsx` pins the sweep end to end (Empty grouping, 403 and 404 handling, failed probes, remount caching, principal isolation, abort on unmount), but no test file targets the hook directly, so the concurrency bound and the nonexistent-array response are not asserted.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial creation |
