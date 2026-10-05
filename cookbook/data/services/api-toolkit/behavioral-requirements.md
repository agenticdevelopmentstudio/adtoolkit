
### Request Building and Execution

- **request-base**: the fixed API base MUST be the fixed string `/api`; every
  built request MUST be same-origin relative to this base, never an absolute
  cross-origin URL.
- **path-substitution**: path substitution MUST replace each `{name}` path
  segment with the URL-encoded value from the supplied path values when
  present, and MUST leave a `{name}` segment visible, unencoded, in the
  resulting path when no matching value is supplied.
- **body-allowed**: the body-allowed check MUST return true only when the
  endpoint's method is one that accepts a body per its metadata; it MUST
  return false otherwise so the request builder never attaches a body to a
  body-less method.
- **request-headers**: the request builder MUST set `Content-Type:
  application/json` only when a body is actually attached, and MUST set
  `Authorization: Bearer <token>` only when a token argument is supplied;
  each header MUST NOT be present when its precondition is absent.
- **mutating-methods**: the mutating-method check MUST return true for every
  HTTP method except `GET`, `HEAD`, and `OPTIONS`, and MUST return false for
  those three.
- **response-normalization**: the request executor MUST resolve to a uniform
  result for every HTTP status code, `2xx` through `5xx` inclusive, and MUST
  record the elapsed wall-clock duration on that result; it MUST NOT throw for
  a non-2xx HTTP response.
- **network-failure-propagation**: the request executor MUST let a
  transport-level failure (offline, DNS failure, a cross-origin block) reject
  its promise rather than resolve to a normalized result; its "never throws"
  contract covers only non-2xx statuses. The endpoint detail view catches the
  rejection and shows its message (falling back to `'Request failed'`).
- **request-timeout**: neither the request builder nor the request executor
  attaches a timeout or a cancellation controller to the underlying request; a
  request that never resolves stays in flight until the browser gives up.

### Endpoint Lookup

- **endpoint-key**: the endpoint key MUST be derived from an endpoint's method
  and path such that endpoint lookup can find the same endpoint by that key.
- **tag-index-caching**: the tag-to-endpoints index MUST be built lazily, on
  first use, and MUST be reused on every subsequent call rather than being
  rebuilt.
- **tag-ordering**: the full tag list MUST be returned in sorted order.
- **endpoints-for-tag-ordering**: the endpoints-for-a-tag lookup MUST return
  that tag's endpoints sorted first by path, then by a fixed method ranking
  for endpoints sharing a path.

### Code Highlighting

- **highlighter-singleton**: the cached highlighter MUST be created at most
  once per process and MUST be reused by every subsequent highlight call
  rather than being re-initialized.
- **highlighter-dual-theme**: the cached highlighter MUST support both a
  light and a dark theme and the JSON, shell, and JavaScript languages.
- **highlighter-failure-recovery**: if highlighter initialization rejects, the
  cache MUST reset back to empty so a subsequent call retries initialization
  rather than being permanently disabled by one transient failure.
- **pretty-json-fallback**: the pretty-JSON fallback MUST return the original
  input text unchanged when parsing fails, and MUST return an empty string
  for blank input; it MUST NOT throw.

### Schema-Derived Examples and Field Descriptions

- **ref-resolution-scope**: reference resolution MUST resolve only local
  schema-component references; a reference outside that local scope MUST NOT
  be treated as resolved.
- **example-cycle-safety**: example derivation MUST thread a "seen" set
  through every recursive step so that a cyclic schema (a schema that refs
  itself, directly or transitively) terminates rather than recursing
  indefinitely.
- **example-precedence**: example derivation MUST resolve an example value by
  trying, in order: reference resolution, `anyOf`/`oneOf` variant selection,
  `allOf` merge, an explicit example, an explicit default, the first `enum`
  value, then a type-driven default — stopping at the first applicable step.
- **type-label-truncation**: the type label MUST append a `?` suffix for a
  nullable type, MUST render a union of variants, and MUST truncate an enum
  preview beyond its fourth value with `…` rather than listing every value.
- **field-description-depth**: field description MUST describe fields exactly
  one level deep (name, type, required, description) after type unwrapping
  has dereferenced a reference, array items, a null-union, and a merged
  `allOf`.

### Endpoint Slugging

- **slug-projection**: slug projection MUST strip `{param}` braces from every
  path segment and MUST append the method, lower-cased, as the final slug
  segment.
- **slug-collision-detection**: the lazily-built slug index MUST throw when
  two distinct endpoints project to the same slug, rather than silently
  letting the second endpoint alias or shadow the first.
- **slug-lookup-miss**: slug lookup MUST return nothing, not throw, when no
  endpoint maps to the given slug.

### Snippet Generation

- **snippet-token-placeholder**: every generated snippet MUST embed a fixed
  token placeholder (the literal string `YOUR_TOKEN`) in place of any real
  bearer token; a generated snippet MUST NOT embed a live, caller-supplied
  token.
- **snippet-body-inclusion**: the generated snippet's body text MUST include a
  request body only when the endpoint's metadata declares a request body and
  the supplied body, once trimmed, is non-empty.
- **curl-snippet-escaping**: the command-line snippet MUST single-quote an
  embedded JSON body and MUST shell-escape any single quote that occurs
  inside that body.

### Method and Status Tone Mapping

- **method-tone-mapping**: the method badge/dot class mapping MUST map each of
  `GET`, `POST`, `PUT`, `PATCH`, `DELETE` to that method's fixed badge/dot
  classes, and MUST fall back to the neutral class for any other method.
- **method-text-class-consistency**: the method text class MUST always equal
  the first space-delimited token of the method's badge class for every
  method, so the badge and the text-only rendering can never drift onto
  different palettes.
- **status-tone-mapping**: the status tone mapping MUST map `200`–`299` to
  the green tone, `400`–`499` to the orange tone, `500` and above to the red
  tone, and any other status to the muted tone.

### Server and Client Entry Points

- **server-entry-safe-for-server-use**: the server-usable entry point MUST
  NOT carry a marker that forces client-side rendering machinery, so it can
  be imported from server-only code without pulling client-bundling
  requirements with it.
- **client-barrel-excludes-metadata**: the client-facing entry point MUST NOT
  re-export endpoint lookup or the generated endpoint list; a component
  imported from the client-facing entry point MUST NOT bundle the generated
  endpoint metadata as a transitive dependency.
- **shared-cache-via-package-path**: the server-usable entry point MUST reach
  the tag index, endpoint-for-tag lookup, endpoint lookup, and endpoint key
  functions through a path that resolves to the same module instance as the
  client-facing entry point uses, so that the server entry and the client
  entry — two separate build chunk graphs — observe the same module-level
  cache instance rather than each forking its own copy.

### Column Editability

- **server-managed-lock**: a column marked server-managed MUST NOT be
  editable in any mode, regardless of any override.
- **override-precedence**: an editability override MUST take effect only for
  a non-relational, non-server-managed column; an override MUST NOT make a
  relational (primary-key or foreign-key-shaped) column, nor a
  server-managed column, editable.
- **relational-create-only**: a relational column (a primary-key member, an
  exact match against a known set of identifier field names, or a match
  against a fixed identifier-suffix pattern) MUST be editable only when the
  mode is create, never in edit mode.
- **create-only-lock-on-edit**: a column marked create-only MUST NOT be
  editable once the mode is edit.
- **default-editable**: a column that is not server-managed, not relational,
  and not locked by the create-only flag in edit mode MUST be editable by
  default.
- **hidden-columns**: the hidden-column check MUST return true only for a
  server-managed column.

### Row Edit Tracking

- **dirty-detection**: dirty detection MUST return true if and only if at
  least one key present in the edit set has a value that is strictly
  different from the same key's value in the baseline; because the edit set
  MUST carry only the columns that were actually changed, iterating its keys
  MUST be sufficient — dirty detection MUST NOT need to inspect any key absent
  from the edit set.
- **draft-merge-immutability**: draft merging MUST return a new object
  overlaying the edit set onto the baseline, and MUST NOT mutate either the
  baseline or the edit set.

### Table Visibility Gate

- **presentation-only-gate**: the read/write allowlist checks MUST be
  documented and treated as presentation-only; they MUST NOT be relied upon
  as the authorization boundary — the server MUST independently re-check
  every request regardless of what the client renders.
- **read-allowlist**: the read-allowlist check MUST return true for
  owner and catalog exposure for any viewer, and MUST return true for admin
  exposure only when the viewer is an admin.
- **write-allowlist**: the write-allowlist check MUST return true for owner
  exposure for any viewer, and MUST return true for catalog or admin exposure
  only when the viewer is an admin.
- **fail-closed-on-unknown-tier**: a table whose exposure tier is missing or
  unrecognized MUST be denied both read and write for a non-admin viewer; the
  readable-tables filter MUST exclude such a table from its filtered result
  for a non-admin viewer.
- **order-preserving-filter**: the readable-tables filter MUST preserve the
  input order of the tables it retains.

### Schema Allowlist

- **schema-allowlist-single-source**: the schema allowlist MUST be computed
  exactly once, at load time, from the generated table list, and MUST serve
  as the single source of truth consulted by both halves of the
  allowlist-to-feature lockstep check.

### CRUD Resource State

- **item-url-substitution**: the item URL builder MUST substitute each
  primary-key value, URL-encoded, into the item path to build the per-item
  URL.
- **row-key-derivation**: the row key MUST join the row's escaped
  primary-key values, and MUST return the empty string when a single-key row
  has no value for that key.
- **loading-vs-fetching**: "loading" MUST mean "nothing to show for the
  current list yet" and "fetching" MUST mean "a list call is currently open";
  the two MUST be able to diverge (e.g. a background re-list on an
  already-populated list has fetching true but loading false).
- **out-of-order-response-guard**: the state MUST track a sequence number per
  list call and MUST discard the result of any list response whose sequence
  number is not the latest issued, so a slow, stale response MUST NOT
  overwrite state written by a newer, faster response.
- **loaded-for-tracking**: the state MUST track which list identity's rows
  are currently on screen, and "loading" MUST be derived as "fetching is true
  and the currently-loaded list differs from the requested one" so switching
  to a not-yet-loaded list shows loading, while re-fetching an
  already-loaded list does not.
- **query-composition-order**: the list query string MUST place the
  scope-derived query segment before the filter query segment when both are
  present.
- **mutation-relist**: create, update, and remove MUST re-issue the list call
  after their underlying mutation succeeds; the raw create/update/remove
  mutators they call MUST NOT re-list on their own.
- **delete-uses-authed-request**: row removal MUST call the
  response-body-discarding authenticated request helper, not the
  JSON-parsing authenticated request helper, because the delete endpoint
  answers `204 No Content` and the JSON-parsing helper throws on a `204`.
- **mutation-error-not-hook-state**: a failure from create, update, or remove
  MUST propagate to the caller as a rejected promise, and MUST NOT be written
  into the state's own error field.

### Exit Guard Channel

- **stable-proxy-identity**: the exit-guard proxy returned while a guard is
  registered MUST be the same object identity across re-registrations (built
  once, with no dependency that would cause it to be rebuilt).
- **presence-is-the-dirty-signal**: the channel MUST expose the proxy
  (non-null) only while a guard is present, and MUST expose nothing once
  withdrawn; callers MUST treat the presence of a non-null guard, not merely
  a call to it, as part of the dirty signal.
- **proxy-reads-latest-guard**: the stable proxy's dirty check MUST read
  through to the most recently registered guard rather than closing over a
  stale one.

### Viewer State

- **standalone-default**: the viewer state MUST return the settled value
  "not an admin, ready" when no authentication provider is present, so the
  browser is usable standalone without ever reporting an unsettled/loading
  state.
- **admin-derivation**: when an authentication provider is present, the
  admin flag MUST be derived from an admin check against the current user
  and readiness MUST be derived from the negation of the provider's loading
  state — readiness MUST distinguish "settled" from "still loading," never
  conflating the two.

