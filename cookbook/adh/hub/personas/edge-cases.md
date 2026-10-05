
- An empty persona list renders the root level's empty message, `"No personas yet."`, rather than
  an empty items array with no explanation.
- A facet id present in the facet rail but outside the currently supported set (8 of the 13
  declared facets) MUST resolve to the fixed unavailable-facet notice, never to a broken or
  partially-rendered form.
- A path whose facet id matches nothing in the declared facet set (not merely an unsupported id,
  but an unknown one) MUST resolve to an empty result the same way an unknown persona id does.
- Every blank optional text field on a facet save (`description`, `character`, `voice`,
  `examples`) is mapped to absent through the blank-to-nothing helper, never persisted as `""`.
- Selecting the `"llm"` facet's `model` for a service that does not actually offer that model id
  (stale selection, or the service was switched) MUST clear `model` to absent on save rather than
  persist a mismatched pair.
- Any failure from the underlying data source (e.g. offline) on the root-level listing,
  child-content resolution, create, save, or delete MUST propagate as a wrapped domain error,
  never be swallowed.
- The demo-eligibility check treats a raw config that is not an object at all (`"not even an
  object"`) the same as one that is well-formed but switched off: `false`, with no thrown error.
- Listing interest documents on a corpus with more than 500 documents silently returns only the
  first (oldest-id-first) 500; the caller receives no signal that more documents exist.
- The demo-preview operation called with a `history` longer than the maximum preview-history
  length is rejected by the server with a 400; this client sends the caller's history as given and
  applies no truncation of its own.
- Updating a special interest given a patch that includes `personaId` or `bucketId` silently drops
  both from the outgoing request rather than sending (and having the server reject) them.

