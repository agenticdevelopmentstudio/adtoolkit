
- **Empty lookup name.** Looking up a model by the empty-string name — the
  name index and the canonical-id index (whose canonical form of the empty
  string is itself the empty string) both miss unless a model entry
  literally has `id == ""`; the lookup MUST return no match.
- **Sparse decode.** A JSON model object carrying only `"id"` — `aliases`
  and `capabilities` MUST decode to `[]`, `description` MUST decode to
  absent, rather than failing the whole catalog's decode.
- **Model with zero aliases.** A model entry whose `aliases == []` (e.g. the
  sample's `llama-3.3-70b-instruct`) MUST still resolve by its own `id`
  through the canonical-id index.
- **Empty catalog.** A catalog constructed with `models: []` MUST build
  empty indexes; every model-name lookup MUST return no match and every
  resolution MUST return an empty resolved model, never fail.
- **Full-size shipped catalog.** The bundled resource carries 566+ models
  across 26+ gateways; the same index-based lookup and merge logic MUST
  behave identically at that scale as in the two-model unit-test fixture —
  no size-dependent branch exists in the implementation.
- **Concurrent reads.** Model entries, offering records, resolved models,
  and the catalog itself are immutable value types built entirely during
  construction, with no mutable stored state afterward, so concurrent reads
  from multiple threads or tasks MUST be safe with no locking — this is
  applicable (the catalog is read from UI code and could be read from
  background contexts too) and is safe by construction, not merely
  untested.
- **Missing, unreadable, or malformed bundle resource.** Loading the catalog
  MUST return no result for all three (the resource cannot be located; the
  resource's data cannot be read; the JSON fails to decode), and the shared
  catalog instance MUST fall back to the empty catalog rather than crash.
- **Id/alias collision between two distinct models.** No validation exists;
  index construction's last write for a given key wins deterministically
  (see `alias-collision-last-writer-wins`), with no diagnostic distinguishing
  "intended override" from "generator bug." This is a stated fact, not a
  gap, because the resulting behavior is fully deterministic and traceable.
- **Curated model detail lookup is exact-match only.** Looking up a
  template's curated model detail matches only by exact id — no
  lowercasing, no canonicalization fallback, unlike a model-name lookup
  against the catalog. A template whose curated entry is spelled differently
  from its own models list entry SHOULD have matching spellings, or
  curation silently does not apply for that model.
- **Empty-string curated description is treated as absent.** Resolving a
  model MUST fall back to the shared model's description when the curated
  description is present but an empty string, exactly as it does when the
  curated value is absent — the two are indistinguishable to a caller of the
  resolution.
- **Canonicalization suffix ordering.** A model name ending in `-fp8-fast`
  MUST have the whole four-token suffix stripped, not just `-fp8`, because
  canonicalization checks the fixed suffix list in the order given and
  returns on the first match.
- **No network dependency (offline/disconnected: not applicable).** The
  catalog performs no network I/O of any kind — it reads only a bundled
  local JSON resource. There is no online/offline distinction for this
  component; connectivity loss elsewhere in the host app cannot affect it.

