
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| resource-data-001 | percent-encodes-uri-components | the string `a b` | `a%20b` |
| resource-data-002 | compact-drops-undefined-preserves-null | an object with one key set to `1`, one key absent, one key set to `null` | `{ that key: 1, the null key: null }`, the absent key dropped |
| resource-data-003 | compact-non-mutating | an object with one key left absent, passed through the compacting helper | the original object still carries that key with an absent value afterward |
| resource-data-004 | narrow-fallback | value `'x'`, allowed values `['a', 'b']`, fallback `'a'` | `'a'` (fallback, since `'x'` is not allowed) |
| resource-data-005 | scope-by-owner-filters | rows `[{owner:1},{owner:2}]`, owner id `1` | `[{owner:1}]` |
| resource-data-006 | sort-by-text-non-mutating | rows `[{name:'b'},{name:'a'}]` sorted by name | returned array is `[{name:'a'},{name:'b'}]`; the original array is unchanged |
| resource-data-007 | workspace-query-encodes | workspace `'a b'` | `'?workspace=a%20b'` |
| resource-data-008 | workspace-query-encodes | no workspace supplied | `''` |
| resource-data-009 | data-config-default | the configuration reader called with no prior configuration set | the shipped default storage-key prefix (see Configuration) |
| resource-data-010 | configure-data-merges | setting the storage-key prefix to `'x'`, then reading configuration | storage-key prefix `'x'` |
| resource-data-011 | ftd-key-shape | writing last-shown id `'p-1'` for collection `'projects'` with prefix `'x'` | writes under storage key `'x:ftd:projects:lastId'` |
| resource-data-012 | read-last-id-null-safe | reading the last-shown id for `'projects'` with nothing stored | no value |
| resource-data-013 | read-last-id-null-safe | reading the last-shown id for `'projects'` when reading storage fails | no value, no failure propagates |
| resource-data-014 | write-last-id-swallow | writing last-shown id `'p-1'` for `'projects'` when writing storage fails | resolves without raising |
| resource-data-015 | clear-last-id-swallow | clearing the last-shown id for `'projects'` when removing storage fails | resolves without raising |
| resource-data-016 | read-view-mode-safe-without-storage | reading the view mode for `'projects'`/`'root'` with no persisted-storage environment available | `'cards'` |
| resource-data-017 | read-view-mode-validates | reading the view mode for `'projects'`/`'root'` with `'grid'` stored | `'cards'` (invalid value rejected) |
| resource-data-018 | read-view-mode-validates | reading the view mode for `'projects'`/`'root'` with `'list'` stored | `'list'` |
| resource-data-019 | write-view-mode-swallow | writing view mode `'list'` for `'projects'`/`'root'` when storage fails | resolves without raising |
| resource-data-020 | http-re-exports-auth | importing the shared authenticated-request operation from this module | resolves to the same operation the Auth Client recipe exports |
| resource-data-021 | http-status-duck-typed | the status-code extractor given an error carrying status `404` | `404` |
| resource-data-022 | http-status-duck-typed | the status-code extractor given a plain error with no status | no value |
| resource-data-023 | client-refusal-shape | the client-refusal constructor given message `'bad input'` | an error with message `'bad input'` and status `400` |
| resource-data-024 | is-not-found-derivation | the not-found predicate given an error with status `404` | `true` |
| resource-data-025 | is-conflict-derivation | given status `409` | `true` |
| resource-data-026 | is-forbidden-derivation | given status `403` | `true` |
| resource-data-027 | is-service-unavailable-derivation | given status `503` | `true` |
| resource-data-028 | err-msg-fallback | given an error with message `'boom'`, fallback `'fallback'` | `'boom'` |
| resource-data-029 | err-msg-fallback | given a non-error value `'not an error'`, fallback `'fallback'` | `'fallback'` |
| resource-data-030 | rethrow-conflict-friendly | given an error whose message is `'a project with this name already exists'`, friendly message `'Pick another name'` | raises an error with message `'Pick another name'` |
| resource-data-031 | rethrow-conflict-friendly | given an error with message `'network down'` | rethrows the original error unchanged |
| resource-data-032 | decode-jwt-claims-shape | decoding the token-claims of `'not-a-jwt'` (no dots) | no value |
| resource-data-033 | decode-jwt-claims-shape | decoding a well-formed three-part token whose middle part is valid base64url JSON | the decoded claims object |
| resource-data-034 | decode-jwt-claims-null-safe | decoding a three-part token whose middle part is not valid base64url | no value |
| resource-data-035 | tenant-id-priority | claims containing both an ecosystem id `'e1'` and a tenant id `'t1'` | `'e1'` |
| resource-data-036 | tenant-id-priority | claims containing a tenant id `'t1'` and a project id `'p1'` | `'t1'` |
| resource-data-037 | tenant-id-priority | no token present | no value |
| resource-data-038 | use-tenant-id-memoized | the tenant-id read state rendered twice against the same underlying token | returns the same tenant id both times without re-decoding |
| resource-data-039 | resource-item-key-shape | cache key `'projects'`, tenant `'t1'`, item id `'p-1'` | `('resource-item', 't1', 'projects', 'p-1')` |
| resource-data-040 | revalidate-resource-items-delegates | invalidating every resource-item entry whose cache key matches `'projects'` | every matching entry is invalidated |
| resource-data-041 | resource-item-cache-key-includes-tenant | the resource-item read state for cache key `'projects'`, item `'p-1'`, under tenant `'t1'` | cache key `('resource-item', 't1', 'projects', 'p-1')` |
| resource-data-042 | resource-item-enabled-gate | the resource-item read state with no item id supplied | the load operation is never invoked |
| resource-data-043 | resource-item-error-reporting-gated | the load operation fails with error reporting left at its default | the failure is reported naming the resource-item feature, the load step, and cache key `'projects'`, before the failure propagates |
| resource-data-044 | resource-item-error-reporting-gated | the load operation fails with error reporting explicitly disabled | the failure is not reported; it still propagates |
| resource-data-045 | resource-item-no-retry | the load operation fails once | no retry occurs; the error is set after the first failure |
| resource-data-046 | resource-item-cache-retention | inspecting the read state's resolved cache settings | the retention period equals the configured 30-minute value (1,800,000 ms) |
| resource-data-047 | resource-item-placeholder-data | a seed value is supplied before the load settles | the seed value is shown and the settled indicator is `false` |
| resource-data-048 | resource-item-is-settled-sticky | the load resolves, then a background refresh begins for the same item id | the settled indicator remains `true` throughout the refresh |
| resource-data-049 | resource-item-is-missing-derivation | the load fails with a not-found-shaped error | the missing indicator is `true` |
| resource-data-050 | resource-item-error-message-fallback | the load fails with a plain string value rather than an error | the error message is `'Failed to load.'` |
| resource-data-051 | resource-item-reload-null-id-behavior | calling reload with no item id | the read is re-run and the load call receives the absent id, as stated in the requirement; not exercised by the reference tests |
| resource-data-052 | resource-item-writer-write-or-evict | writing a non-null row through the cache writer | the row is written into the cache |
| resource-data-053 | resource-item-writer-write-or-evict | writing a null value through the cache writer | the cache entry is evicted, not written as a null placeholder |
| resource-data-054 | resource-item-prefetch-never-throws | prefetching an item whose load fails | the prefetch call never raises |
| resource-data-055 | resource-item-prefetch-cleanup-conditional | a prefetch's load fails, then a concurrent mount's load for the same id succeeds before the prefetch's cleanup runs | the entry is left holding the successful data, not removed |
| resource-data-056 | resource-list-key-shape | cache key `'projects'`, tenant `'t1'` | `('resource-list', 't1', 'projects')` |
| resource-data-057 | revalidate-resources-delegates | invalidating every resource-list entry whose cache key is `'workspaces'` | every matching entry is invalidated |
| resource-data-058 | resource-list-error-reporting-gated | the load fails with error reporting left at its default | the failure is reported naming the resource-list feature, the load step, and cache key `'projects'` |
| resource-data-059 | resource-list-no-retry | the load fails once | no retry occurs |
| resource-data-060 | resource-list-cache-retention | inspecting the read state's resolved cache settings | the retention period equals the configured 30-minute value |
| resource-data-061 | resource-list-reload-identity-guard | the same load-function identity passed across two renders | no cancel/refresh occurs |
| resource-data-062 | resource-list-reload-identity-guard | a new load-function identity passed with the same cache key/tenant | the in-flight request is cancelled and refreshed |
| resource-data-063 | resource-list-reload-rethrows | calling reload when the underlying refresh resolves with an error | reload's returned outcome carries that same error |
| resource-data-064 | resource-list-set-items-writes-through | setting new rows through setItems | the rows are written directly into the cache |
| resource-data-065 | resource-list-is-fetching-derivation | a read state actively fetching and still pending its first result | the loading indicator is `true` |
| resource-data-066 | resource-list-error-status-derivation | the load fails with a conflict-shaped (409) error | the error status is `409` |
| resource-data-067 | resource-list-error-message-fallback | the load fails with a plain object rather than an error | the error message is `'Failed to load.'` |
| resource-data-068 | make-entity-delete-handler-sequence | the delete resolves, and the last-shown id for the base path equals the deleted id | the last-shown id is cleared, then navigation to the base path's `all` view occurs, then a reload is attempted |
| resource-data-069 | make-entity-delete-handler-sequence | the delete resolves, and the last-shown id differs from the deleted id | the last-shown id is not cleared; navigation and reload still occur |
| resource-data-070 | make-entity-delete-handler-del-not-caught | the delete itself fails | the handler's outcome carries that failure; navigation never occurs |
| resource-data-071 | make-entity-delete-handler-del-not-caught | the delete resolves but the subsequent reload fails | the handler's outcome still resolves successfully (the reload failure is swallowed) |
| resource-data-072 | workspace-prefs-cache-key | caching workspace `'acme'` with prefix `'x'` | writes under storage key `'x:home:workspace'` |
| resource-data-073 | read-cached-workspace-safe-without-storage | reading the cached workspace with no persisted-storage environment available | returns a safe empty result, no failure raised |
| resource-data-074 | write-cached-workspace-swallow | caching workspace `'acme'` when storage fails | resolves without raising |
| resource-data-075 | workspace-prefs-get-unwraps | reading workspace preferences when the server reports not-found | resolves to an empty object, never raises |
| resource-data-076 | workspace-prefs-get-unwraps | reading workspace preferences when the server returns preferences containing slug `'acme'` | resolves to `{ slug: 'acme' }` |
| resource-data-077 | workspace-prefs-put-full-replace | writing preferences `{ slug: 'acme' }` | issues a PUT request to `/api/me/workspace-prefs` with body `{ slug: 'acme' }` |
| resource-data-078 | workspace-list-cache-key-constant | the workspace-list cache key | `('workspaces')` |
| resource-data-079 | notify-workspaces-changed-dual-invalidate | announcing that the workspace list changed | the workspace-list cache entry is invalidated directly, and a matching invalidation accepts a resource-list entry keyed `'workspaces'` while rejecting one keyed `'organizations'` |
| resource-data-080 | notify-workspaces-changed-swallows | announcing a change when the underlying invalidation fails | does not raise or produce an unhandled failure |
| resource-data-081 | notify-workspaces-changed-dispatches-event | subscribing a listener, then announcing a change | the listener is called exactly once |
| resource-data-082 | on-workspaces-changed-subscribe | subscribing, unsubscribing, then announcing a change again | the listener is not called again |
| resource-data-083 | check-workspace-slug-available | checking availability of slug `'a b'` | issues a GET request to `/api/auth/slug-available/a%20b` |
| resource-data-084 | workspace-list-drops-team-rows | the workspace list includes one row of type `'team'` | that row is excluded from the result |
| resource-data-085 | workspace-list-ordering | the workspace list has one individual row and two organization rows named `'Zeta'` and `'Acme'` | order is `[individual, 'Acme', 'Zeta']` |

