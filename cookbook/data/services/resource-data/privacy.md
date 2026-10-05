
- **Data collected**: This component collects no new personal data of its
  own. It caches, in memory or in persisted local storage, whatever rows
  and preference objects its callers already fetched: resource lists/items
  keyed by an opaque tenant id (ecosystem id/tenant id/project id, read via
  the tenant-id read state, never re-derived or stored separately by this
  module), a last-selected id and view-mode string per collection (FTD),
  and a cached workspace slug.
- **Storage**: The FTD last-id/view-mode values and the cached workspace
  slug live in persisted local storage under keys `<prefix>:ftd:...` and
  `<prefix>:home:workspace` as plaintext — readable by anything with access
  to that storage, the same tradeoff the Auth Client recipe's own Privacy
  section documents for the access token; none of these values is itself a
  credential. Resource lists/items live only in an in-memory cache, never
  written to persisted storage.
- **Transmission**: Every network call this component makes goes through
  the shared authenticated request layer the Auth Client recipe documents;
  this module adds no transmission channel of its own.
- **Retention**: Resource-list/resource-item cache entries persist in
  memory for the configured cache-retention period (30 minutes) after their
  last observer goes away, and the whole cache is cleared the moment the
  signed-in principal changes (a session-watching mechanism outside this
  component, but the reason a tenant-keyed cache entry cannot survive a
  sign-out/sign-in on a shared machine). FTD and workspace-slug
  persisted-storage entries persist until explicitly overwritten or the
  host clears its storage; this component enforces no TTL on them.

