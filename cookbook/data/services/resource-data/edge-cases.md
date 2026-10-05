
- **Null/empty input**: The tenant-id derivation and the token-claims
  decoder MUST return no value for an absent token or an empty string,
  respectively (resource-data-032, resource-data-037). The workspace
  query-string builder MUST return an empty string when no workspace is
  supplied (resource-data-008). Reading the last-shown id with nothing
  stored MUST return no value (resource-data-012).
- **Boundary/malformed values**: A token with no dot, one dot, or a payload
  that is not valid base64url/JSON MUST all decode to no value via the
  token-claims decoder (resource-data-032, resource-data-034), relying
  entirely on the base64url-JSON decoding operation's own contract (see the
  Auth Client recipe) — this component adds no additional payload
  validation of its own. A stored view-mode value that is neither `'cards'`
  nor `'list'` MUST be rejected back to the `'cards'` default rather than
  passed through (resource-data-017).
- **Concurrent access**: A prefetch racing a mount's own read of the same
  item MUST NOT let the prefetch's failure cleanup remove data a concurrent
  success has since written (resource-data-055). Two renders of the
  resource-list read state with the same load-function identity MUST NOT
  cancel/refetch, but a changed load-function identity (with cache
  key/tenant unchanged) MUST (resource-data-061, resource-data-062) —
  this guard exists specifically because a naive effect keyed only on mount
  would otherwise refetch on every render.
- **Error states**: Every read state's underlying load operation MUST
  rethrow whatever its load/delete callback raises after optionally
  reporting it, never swallowing a primary read/write failure
  (resource-item-error-reporting-gated,
  resource-list-error-reporting-gated); the one deliberate exception is the
  entity-delete handler's post-delete reload, whose failure is swallowed
  because the delete itself already succeeded (see Design Decisions).
- **Offline/disconnected state**: Neither the resource-item nor the
  resource-list read state defines its own retry policy for a network-level
  failure — both explicitly disable automatic retry (resource-item-no-retry,
  resource-list-no-retry), so a caller that wants offline resilience must
  layer it on the load/delete callback itself; this component's own
  contract is to surface the failure promptly, not to mask it behind hidden
  retries.
- **Storage unavailable** (private browsing, disabled storage — an edge
  case specific to browser-hosted implementations, with no analog on a
  platform with a conventional persisted-settings store): every last-shown-id
  and view-mode operation and the cached-workspace operations MUST swallow a
  thrown storage exception rather than propagate it, degrading to the
  documented default (no value/`'cards'`) rather than crashing a render.

