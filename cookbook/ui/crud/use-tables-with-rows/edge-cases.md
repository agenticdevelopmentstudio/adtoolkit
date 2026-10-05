
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

