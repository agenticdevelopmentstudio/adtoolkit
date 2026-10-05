
- **percent-encodes-uri-components**: The shared URI-component encoding
  helper MUST behave like standard percent-encoding of a URI component (for
  example, encoding a space as `%20`).
- **compact-drops-undefined-preserves-null**: The object-compacting helper,
  given an object, MUST return a new object containing every key whose value
  is not absent, and MUST preserve any key whose value is explicitly `null`.
- **compact-non-mutating**: The object-compacting helper MUST NOT mutate its
  input object.
- **narrow-fallback**: The allowed-value narrowing helper, given a value, a
  set of allowed values, and a fallback, MUST return the value when it is
  among the allowed values, and MUST return the fallback otherwise.
- **scope-by-owner-filters**: The owner-scoping filter, given a list of
  rows, an owner id, and an owner-extracting function, MUST return exactly
  the rows for which the extracted owner matches the given owner id.
- **sort-by-text-non-mutating**: The text-sorting helper, given a list of
  rows and a field name, MUST return a new array ordered by that field using
  locale-aware comparison, and MUST NOT mutate the input array.
- **workspace-query-encodes**: The workspace query-string builder, given a
  workspace slug, MUST return the query string `?workspace=<percent-encoded
  slug>` when a non-empty workspace is supplied, and MUST return an empty
  string when it is absent or empty.
- **data-config-default**: The data-configuration reader MUST return the
  shipped default storage-key prefix (see Configuration) before any
  configuration has been set; a host namespaces its stored keys by
  configuring the prefix, so no key name in this component is fixed to one
  product.
- **configure-data-merges**: The data-configuration setter, given a partial
  configuration, MUST shallow-merge it onto the current configuration,
  leaving any field it omits unchanged.
- **ftd-key-shape**: Every FTD storage key MUST be built as
  `<prefix>:ftd:<basePath>:<name>`, where `<prefix>` is the configured
  storage-key prefix.
- **read-last-id-null-safe**: Reading the last-shown id for a collection
  MUST return the stored id, and MUST return no value when nothing is stored
  or when reading storage fails.
- **write-last-id-swallow**: Writing the last-shown id MUST swallow any
  failure raised while writing storage.
- **clear-last-id-swallow**: Clearing the last-shown id MUST remove the
  stored id and MUST swallow any failure raised while doing so.
- **read-view-mode-safe-without-storage**: Reading the view mode MUST return
  `'cards'` when no persisted-storage environment is available yet.
- **read-view-mode-validates**: Reading the view mode MUST return the stored
  value only when it is exactly `'list'` or `'cards'`, and MUST return
  `'cards'` for any other stored value, including absence or a reading
  error.
- **write-view-mode-swallow**: Writing the view mode MUST swallow any
  failure raised while writing storage.
- **http-re-exports-auth**: This module MUST re-export, unchanged, the
  shared authenticated-request operations, error-message extraction,
  token/subject reading, and base64url-decoding operations documented by the
  Auth Client recipe — their contract is documented there, not restated
  here.
- **http-status-duck-typed**: The status-code extractor, given an error,
  MUST return its numeric status property when the error carries one, and
  MUST return no value otherwise, without ever checking the error's specific
  class.
- **client-refusal-shape**: The client-refusal error constructor, given a
  message and an optional status (default 400), MUST return an error whose
  message is that message and whose status is that status.
- **is-not-found-derivation**: The not-found predicate MUST return true
  exactly when the status-code extractor reports 404.
- **is-conflict-derivation**: The conflict predicate MUST return true
  exactly when the status-code extractor reports 409.
- **is-forbidden-derivation**: The forbidden predicate MUST return true
  exactly when the status-code extractor reports 403.
- **is-service-unavailable-derivation**: The service-unavailable predicate
  MUST return true exactly when the status-code extractor reports 503.
- **err-msg-fallback**: The error-message-with-fallback helper, given an
  error and a fallback string, MUST return a message derived from the error
  when one can be extracted, and MUST return the fallback otherwise.
- **rethrow-conflict-friendly**: The friendly-conflict rethrow helper, given
  an error and a friendly message, MUST raise a new error with the friendly
  message when the original error's message matches an "already exists"
  pattern (case-insensitive), and MUST rethrow the original error unchanged
  otherwise.
- **decode-jwt-claims-shape**: The token-claims decoder, given a token
  string, MUST split it on `.` and return no value unless the result has
  exactly 3 parts with a non-empty second part; otherwise it MUST return the
  base64url-JSON decoding of that second part.
- **decode-jwt-claims-null-safe**: The token-claims decoder MUST return no
  value when the base64url-JSON decoding of the payload segment fails —
  handled entirely by that decoding operation's own no-value-on-any-failure
  contract (see the Auth Client recipe), not re-implemented here.
- **tenant-id-priority**: The tenant-id derivation, given decoded token
  claims, MUST return, in order, the ecosystem id, else the tenant id, else
  the project id, else no value, and MUST return no value when the token
  itself is absent.
- **use-tenant-id-memoized**: The tenant-id read state MUST read the current
  access token once per render and MUST memoize the derived tenant id on the
  token's own identity.
- **resource-item-key-shape**: The resource-item cache-key builder, given a
  cache key, a tenant id, and an item id, MUST return the ordered tuple
  `('resource-item', tenantId, cacheKey, id)`.
- **revalidate-resource-items-delegates**: The resource-item cache
  invalidation operation, given a match predicate, MUST invalidate every
  resource-item cache entry whose key the predicate accepts.
- **resource-item-cache-key-includes-tenant**: The resource-item read
  state's cache key MUST be the resource-item cache key built from the cache
  key, item id (or an empty id when absent), and the tenant id derived from
  the tenant-id read state.
- **resource-item-enabled-gate**: The resource-item read state MUST NOT
  invoke its load operation when the item id is absent — the read is gated
  off entirely in that case.
- **resource-item-error-reporting-gated**: When the underlying read fails,
  the resource-item read state MUST report the failure (naming the
  resource-item feature, the load step, and the cache key) when error
  reporting is enabled (the default), and MUST rethrow the failure
  regardless of that setting.
- **resource-item-no-retry**: The resource-item read state MUST NOT
  automatically retry a failed read.
- **resource-item-cache-retention**: The resource-item read state's cache
  entries MUST be retained for the configured resource cache-retention
  period (30 minutes) after their last observer goes away.
- **resource-item-placeholder-data**: The resource-item read state MUST use
  a caller-supplied seed value, when given, only as a placeholder shown
  while the real read is pending — never treated as though it were already
  the settled answer.
- **resource-item-is-settled-sticky**: The returned settled indicator MUST
  become true the first time the read settles a real answer for the current
  item id (not a placeholder, not pending, not in flight), and MUST remain
  true for that same id afterward even during a background refresh; it MUST
  reset to unsettled only when the item id itself changes.
- **resource-item-is-missing-derivation**: The returned missing indicator
  MUST equal the not-found predicate applied to the read's error.
- **resource-item-error-message-fallback**: The returned error message MUST
  be absent when there is no error, MUST be the error's own message when it
  carries one, and MUST be the literal string `'Failed to load.'` otherwise.
- **resource-item-reload-null-id-behavior**: The returned reload operation
  MUST re-run the read unconditionally, whether or not there is an item id:
  its documentation says it is a no-op when there is no id, but the
  implementation does not guard on the id, so the underlying load call is
  invoked with the absent id (asserted by a type cast, not checked at
  runtime). A caller MUST NOT call reload when it has no item id.
- **resource-item-writer-write-or-evict**: The resource-item cache writer's
  returned function MUST write the given value into the cache when it is
  not null, and MUST evict the cache entry (never writing a null
  placeholder) when the given value is null.
- **resource-item-prefetch-never-throws**: The resource-item prefetch
  operation's returned function MUST never raise.
- **resource-item-prefetch-no-retry**: The prefetch MUST issue its
  underlying read with no automatic retry.
- **resource-item-prefetch-cleanup-conditional**: After the prefetch
  settles, its cleanup MUST remove the cache entry only if the entry's state
  is still an error at that time, and MUST leave the entry alone if a
  concurrent successful read has since replaced it.
- **resource-list-key-shape**: The resource-list cache-key builder, given a
  cache key and a tenant id, MUST return the ordered tuple `('resource-list',
  tenantId, cacheKey)`.
- **revalidate-resources-delegates**: The resource-list cache invalidation
  operation, given a match predicate, MUST invalidate every resource-list
  cache entry whose key the predicate accepts.
- **resource-list-error-reporting-gated**: When the underlying read fails,
  the resource-list read state MUST report the failure (naming the
  resource-list feature, the load step, and the cache key) when error
  reporting is enabled (the default), and MUST rethrow the failure
  regardless of that setting.
- **resource-list-no-retry**: The resource-list read state MUST NOT
  automatically retry a failed read.
- **resource-list-cache-retention**: The resource-list read state's cache
  entries MUST be retained for the configured resource cache-retention
  period (30 minutes) after their last observer goes away.
- **resource-list-reload-identity-guard**: The resource-list read state's
  refresh behavior MUST cancel the in-flight request and re-fetch only when
  the caller's load-function identity has changed AND the cache
  key/tenant have stayed the same.
- **resource-list-reload-rethrows**: The returned reload operation MUST
  trigger a refresh and MUST rethrow whatever error that refresh resolves
  with.
- **resource-list-set-items-writes-through**: The returned setItems
  operation MUST write the given rows directly into the cache.
- **resource-list-is-fetching-derivation**: The returned loading indicator
  MUST be true whenever the read is either actively fetching or still
  pending its first result.
- **resource-list-error-status-derivation**: The returned error status MUST
  be the status-code extractor's result for the read's error, or absent when
  there is none.
- **resource-list-error-message-fallback**: The returned error message MUST
  be absent when there is no error, MUST be the error's own message when it
  carries one, and MUST be the literal string `'Failed to load.'` otherwise.
- **make-entity-delete-handler-sequence**: The entity-delete handler
  factory's returned handler MUST, in order: await the delete operation for
  the given id; when the last-shown id for the base path equals that id,
  clear the last-shown id; navigate to the base path's `all` view without
  scrolling; then trigger a reload, swallowing any error the reload raises.
- **make-entity-delete-handler-del-not-caught**: A failure from the delete
  operation itself MUST NOT be caught by this handler — only the subsequent
  reload's failure is swallowed.
- **workspace-prefs-cache-key**: The cached workspace slug MUST be stored
  under the key `<prefix>:home:workspace`.
- **read-cached-workspace-safe-without-storage**: Reading the cached
  workspace MUST return a safe empty result (no raised failure) both when no
  persisted-storage environment is available and when reading storage fails.
- **write-cached-workspace-swallow**: Caching a workspace slug MUST swallow
  any failure raised while writing storage.
- **workspace-prefs-get-unwraps**: The workspace-preferences read operation
  MUST issue a GET request to `/api/me/workspace-prefs`, unwrap the
  response's `prefs` field, and MUST default to an empty object rather than
  surface a not-found result.
- **workspace-prefs-put-full-replace**: The workspace-preferences write
  operation MUST issue a PUT request to `/api/me/workspace-prefs` with the
  full preferences object, replacing the stored preferences rather than
  merging into them.
- **workspace-list-cache-key-constant**: The workspace-list cache key MUST
  be the constant `('workspaces')`.
- **notify-workspaces-changed-dual-invalidate**: The
  workspace-list-changed announcement operation MUST invalidate the
  workspace-list cache entry directly, AND MUST invalidate, via the
  resource-list cache invalidation operation, every resource-list cache
  entry whose cache key is `'workspaces'`.
- **notify-workspaces-changed-swallows**: Both invalidations the
  workspace-list-changed announcement performs MUST swallow any failure
  they produce.
- **notify-workspaces-changed-dispatches-event**: The
  workspace-list-changed announcement operation MUST broadcast an event
  named by the workspaces-changed event name (see Configuration for its
  shipped default), and MUST be a no-op when no environment capable of
  receiving it is available.
- **on-workspaces-changed-subscribe**: The workspace-list-changed
  subscription operation, given a listener, MUST subscribe it to that event
  and MUST return an unsubscribe function; both MUST be no-ops when no
  environment capable of delivering the event is available.
- **check-workspace-slug-available**: The workspace-slug availability
  check, given a slug, MUST issue a GET request to
  `/api/auth/slug-available/<percent-encoded slug>` and return a
  slug-availability result.
- **workspace-list-drops-team-rows**: The workspace-list operation MUST
  exclude any row whose type is `'team'`.
- **workspace-list-ordering**: The workspace-list operation MUST order the
  caller's own individual workspace first, followed by every organization
  sorted by name via the text-sorting helper.

