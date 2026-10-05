
### Cross-cutting (all five topics)

- **ecosystem-scoped-navigation**: every rail path resolution MUST scope its
  data-source calls to the given ecosystem's id; every topic passes that id through
  on every call, including the storage-tokens topic passing it through to the shared
  token rail.
- **path-depth-dispatch**: for sign-in apps, feature flags, server bags, and storage
  tokens, a rail path resolution MUST return a level when the path is empty, MUST
  look up the matching entity by id/key and return a detail when found or an empty
  result when not found for a one-segment path, and MUST return an empty result for
  any longer path. User auth has no level at all: an empty path MUST return the
  single detail, and any non-empty path MUST return an empty result.
- **hub-error-wrapping**: every data-source call in each of the five topics — except
  the storage-tokens topic's create call, which uses a different pattern (see
  **tokens-create-three-way-catch**) — MUST be wrapped in the shared error-wrapping
  step, so a thrown transport/API error is normalized to a shared error kind before
  it reaches the caller.

### User Auth

- **auth-detail-only-entry**: the entry point MUST declare that it leads straight to
  a detail — there is no list level for this topic; navigating to it goes straight
  to the one settings form.
- **auth-field-order**: the detail's form specification MUST present fields in the
  order `signupMode`, `signupHelp`, `loginEnabled`, grouped into a "Sign-up" section
  (`signupMode` select plus a read-only `signupHelp` line) and a "Sign-in" section
  (the `loginEnabled` toggle).
- **auth-signup-options**: the `signupMode` select field's options MUST be every
  recognized sign-up mode in a fixed declaration order (`open`, `inviteOnly`,
  `closed`), titled "Open", "Invite only", "Closed" respectively.
- **auth-signin-help-text**: the `loginEnabled` toggle's help text MUST be the fixed
  string "When off, no one can sign in to this ecosystem." — it does not vary by
  ecosystem or current setting.
- **auth-save-sends-both-values**: the save action MUST always construct an update
  carrying both `signupMode` and `loginEnabled`, never a partial patch, even if only
  one field changed.
- **auth-save-fallback-values**: if the submitted `signupMode` value cannot be
  parsed into a recognized sign-up mode, the save action MUST silently fall back to
  `inviteOnly`; if the submitted `loginEnabled` value is missing, it MUST fall back
  to `false`. Both are documented, in-source fallbacks, not swallowed errors — the
  field's fixed option set makes an invalid `signupMode` value unreachable through
  normal use.
- **auth-detail-id-format**: the detail's id MUST be the string
  `auth-settings:<ecosystem.id>`.
- **auth-no-delete-action**: the detail's delete action MUST be absent — auth
  settings can be edited but never removed.
- **auth-allowed-providers-not-editable**: the user-auth record's `allowedProviders`
  list decodes from the read operation's response, but the detail's form
  specification never reads, displays, or edits it, and the update shape has no
  field to write it back; this component offers no way to view or change the
  allowed providers.

### Sign-in Apps

- **signinapps-list-sort**: the level's items MUST be sorted by `name` using a
  case-insensitive, locale-aware comparison ("Admin console" before "Shop web");
  each item's sublabel MUST be the app's full `slug` (e.g. "shop.shop-web").
- **signinapps-leaf-computation**: the leaf-computation step MUST strip the
  `"<ecosystem.slug>."` prefix from `slug` when present, returning `slug` unchanged
  when it is not — a defensive fallback, since the server prefixes the client slug
  with the ecosystem slug and forces the ecosystem, so every listed `slug` is
  expected to carry that prefix in practice.
- **signinapps-create-fields**: the create form specification MUST expose only
  `name` and `clientId`; `allowedReturnOrigins` and `githubEnabled` are editable
  only after creation, in the detail.
- **signinapps-duplicate-leaf-check**: before calling create, the save action MUST
  reject a `clientId` whose lowercased value matches any existing app's lowercased
  leaf, with the message `App id "<leaf>" is already in use.`.
- **signinapps-clientid-pattern**: the `clientId` field MUST validate against the
  shared slug-format rule with message `App id must be a lowercase token, e.g.
  my-app.` before the duplicate check runs.
- **signinapps-create-conflict-message**: a conflict error thrown by create MUST be
  caught and re-thrown as a validation error reading `A sign-in app "<leaf>" already
  exists in this ecosystem.`; any other error MUST be re-wrapped through the shared
  error-wrapping step.
- **signinapps-origin-validation**: the origin-validation step MUST return no error
  for an acceptable origin and, for a rejected one, the first-violated-rule message:
  not-a-URL ("... is not a valid URL."), non-http(s) scheme ("... must be http(s)."),
  embedded credentials ("... must not include credentials."), or a
  non-empty/non-"/" path, query, or fragment ("... must be just a scheme + host (no
  path).").
- **signinapps-origin-canonicalization-and-dedup**: the origin-canonicalization step
  MUST lowercase the scheme and host and drop a trailing slash while preserving the
  port (e.g. `"HTTPS://Example.com:8443/"` → `"https://example.com:8443"`); the
  origin-list canonicalization step MUST validate every raw origin (throwing a
  validation error on the first failure), then canonicalize and de-duplicate in
  first-seen order.
- **signinapps-start-url-placeholder**: the start-URL text MUST be a fixed,
  non-resolvable placeholder-templated string of the form
  `<your-adh-auth-host>/oauth/signin/start?clientId=<clientID>&providerId=github&return=<your-app-origin>/auth/callback`
  — it is documentation text for the detail's read-only "Start URL" field, not a URL
  the app itself ever fetches.
- **signinapps-detail-fields**: the detail form specification MUST present fields in
  the order `name`, `slug`, `githubEnabled`, `allowedReturnOrigins`, `startURL`;
  `slug` is read-only.
- **signinapps-delete-confirmation**: the delete action's title MUST be "Delete
  sign-in app" and its confirmation text MUST be `Delete sign-in app "<app.name>"?
  Apps using it will stop signing in.`.
- **signinapps-unknown-app-empty**: a path segment id matching no existing app's id
  MUST return an empty result.
- **client-slug-normalization**: the alternate client's create operation MUST trim
  and lowercase the submitted `slug` and trim the submitted `name` client-side
  before sending the create request — a defensive normalization not strictly
  required at create time, since the `clientId` field's slug-format rule already
  constrains it to lowercase in the primary implementation.
- **conflict-message-parity**: the alternate client's create operation's conflict
  handling MUST use the message `A sign-in app "<slug>" already exists in this
  ecosystem.` — identical wording to **signinapps-create-conflict-message**,
  keeping the two implementations' user-visible error text in parity.
- **origin-validation-delegated**: the alternate client's create/update operations
  MUST forward `allowedReturnOrigins` with no client-side format check of their own;
  the equivalent scheme/credentials/path checks (mirroring
  **signinapps-origin-validation**) live in a separate presentation-layer file
  outside this component's given sources, not in the data-client layer itself (see
  Design Decisions).
- **leaf-helper-absent**: the alternate client's own data shape has no equivalent of
  the leaf-computation step; a caller on that side that needs the ecosystem-stripped
  leaf must recompute it from `slug` and the ecosystem's own slug itself.

### Feature Flags

- **flags-no-cache-per-call**: the rail path resolver MUST fetch the flag list
  fresh on every invocation — there is no in-memory cache of the flag list between
  calls.
- **flags-list-sort-and-sublabel**: the level's items MUST be sorted by `key`
  ascending (e.g. `["dark_mode", "new_checkout"]`); each item's sublabel MUST be
  "On" or "Off", with " · <description>" appended when `description` is non-empty,
  and its icon MUST visually distinguish the enabled state from the disabled state.
- **flags-create-fields**: the create form specification MUST expose `key`,
  `description`, `enabled` in that order; `key` is required.
- **flags-duplicate-key-check**: before calling create, the save action MUST reject
  a `key` already present in the passed-in `existing` list with `A flag named
  "<key>" already exists.`; a conflict error from the network call itself MUST be
  caught and re-thrown with the identical message.
- **flags-detail-fields**: the detail form specification MUST present `key`
  (read-only), `enabled`, `description` in that order; the update sent on save MUST
  fall back to the current `flag.enabled`/`flag.description` for any field the
  values dictionary omits.
- **flags-delete-confirmation**: the delete action's title MUST be "Delete flag" and
  its confirmation text MUST be `"<flag.key>" will be removed. Anything reading it
  falls back to its default.`.
- **flags-detail-id-format**: the detail id MUST be
  `feature-flag:<ecosystem.id>:<flag.key>`.
- **flags-key-charset-unrestricted**: neither the create form's `key` field in the primary
  implementation nor the alternate client's create operation/dialog state enforces any
  character-set restriction on a feature-flag key — only non-blank and non-duplicate are checked —
  yet the key is later embedded unescaped in the colon-delimited composite id
  `feature-flag:<ecosystem.id>:<flag.key>` and used directly as a navigation-item id, so a key
  containing a colon could collide with another item's composite id.
- **flag-key-immutable-in-path**: the alternate client's update/delete operations
  MUST address a flag by embedding its `key` in the request path, never in the
  body — the key is immutable once created, matching the primary implementation's
  use of `key` as the flag's own identifier.
- **flags-no-precheck-in-alternate-client**: the alternate client's create operation
  MUST send the request unconditionally and let a duplicate key surface as whatever
  status the backend returns; unlike the primary implementation's create form, it
  performs no pre-flight duplicate check against an existing list and does not
  intercept a conflict into a friendlier message.

### Server Bags

- **bags-list-preview**: the level's items MUST be sorted by `key` ascending, with
  sublabel set to the bag's value collapsed to one line by splitting on newlines and
  rejoining with a single space (e.g. `{ "maxItems" : 20 }`).
- **bags-create-fields**: the create form specification MUST expose `key`, `value`
  (a required JSON-value field), `description`, in that order.
- **bags-json-parse-before-duplicate-check**: in the create save action, `value`
  MUST be parsed via the value-parsing step before the duplicate-`key` check runs —
  invalid JSON with a taken key still surfaces the JSON error first.
- **bags-invalid-json-message-generic**: the value-parsing step MUST discard the
  underlying decode error's specific message and throw a validation error reading
  `Value must be valid JSON — e.g. true, 42, "text", or {"a": 1}.` instead.
- **bags-duplicate-key-check**: the same dual client-pre-check-plus-conflict-catch
  pattern as feature flags applies, with the message `A bag named "<key>" already
  exists.`.
- **bags-detail-full-replace-on-save**: the detail save action MUST re-parse
  `value` from the form's current text on every save and send it as a full
  replacement in the update's `value` field, never a merge of the previous and new
  JSON.
- **bags-removal-message-distinct-from-flags**: the server-bags delete
  confirmation's removal message ("will be deleted. Anything reading it gets
  nothing — there is no default.") MUST NOT reuse the feature-flags delete
  confirmation's message ("will be removed. Anything reading it falls back to its
  default.") — server bags have no default fallback, unlike feature flags, so
  borrowing the flags' message would promise a fallback that does not exist (see
  Design Decisions).
- **bags-json-equality-int-number**: the wrapped JSON value type's equality and
  hashing MUST treat an integral floating-point number and a plain integer as the
  same value whenever they represent the same integral quantity — e.g. a stored
  value of `20` (decoded as a floating-point JSON number), updated by typing
  `{"maxItems": 50}`, produces an update whose value is written as the integer `50`
  even though the original was decoded as a floating-point `20` — this exists
  because naive derived equality otherwise misfires a form's dirty-check.
- **bag-value-validation-delegated**: the alternate client's bag data shapes MUST
  leave `value` untyped, and that layer performs no JSON-shape validation of its
  own — the equivalent of the value-parsing step's parse-or-reject behavior lives
  in a sibling presentation-layer package outside this component's given sources,
  not in the data-client layer itself (see Design Decisions).

### Storage Access Tokens

- **tokens-shared-rail-parameterization**: the shared token rail's resolution
  operation MUST serve both the ecosystem-scoped case and the caller's-own-tokens
  case through the same operation, parameterized only by the ecosystem id (or its
  absence), the level id, and the title.
- **tokens-ecosystem-scoping-via-parameter**: the create form's save action MUST
  always construct its create body with no ecosystem id of its own — ecosystem
  scoping happens exclusively through the operation's own ecosystem-id parameter,
  never through the body's own ecosystem-id field.
- **tokens-about-text-variant**: the rail's about-text MUST return the no-ecosystem
  variant when no ecosystem id is given and the ecosystem-scoped variant otherwise.
- **tokens-name-pattern**: the create form's `name` field MUST validate against the
  shared slug-format rule ("Use lowercase letters, numbers and hyphens.").
- **tokens-create-three-way-catch**: the create form's save action MUST catch
  errors in three tiers: a conflict error becomes a validation error with a fixed
  "name taken" message; any other shared error kind MUST be re-thrown unchanged;
  any error outside that shared taxonomy MUST become a generic unexpected error
  with a fixed message, discarding the original error's own message. This is an
  explicitly different pattern from the shared error-wrapping convention used
  everywhere else in this component (see Design Decisions).
- **tokens-reveal-once-on-create**: on a successful create, the raw secret MUST be
  stored in the revealed-secrets store keyed by the created token's id.
- **tokens-detail-extra-fields-while-revealed**: the token detail MUST append
  `token` and `notice` read-only fields — with `notice` set to the fixed reveal
  notice ("Copy this token now — you won't be able to see it again.") — only while
  the revealed-secrets store holds a value for that token, and MUST set the
  on-screen-token marker to that token's id as a side effect of building that
  detail.
- **tokens-expire-revealed-secret-on-navigate**: the secret-expiry check MUST run
  at the top of every rail path resolution; it MUST drop the revealed secret and
  clear the on-screen-token marker when navigating to any destination other than
  the detail currently showing the secret, and MUST leave it untouched when
  re-rendering that same detail.
- **tokens-revoke-clears-revealed-secret**: the revoke action MUST wrap the revoke
  operation in the shared error-wrapping step and then clear that token's entry in
  the revealed-secrets store, regardless of whether a value was present.
- **tokens-no-save-action-on-detail**: the token detail's save action MUST be
  absent — a storage token has no editable fields once created, only revoke.
- **tokens-delete-confirmation**: the revoke action's title MUST be "Revoke token"
  and its confirmation text MUST be `Revoke storage token "<token.slug>"? Anything
  using it will lose access to its bucket.`.
- **tokens-detail-date-formatting**: the `lastUsed`/`created`/`expires` fields MUST
  format through the shared date-display helper, falling back to "never
  used"/"never" respectively when the underlying value is absent.
- **dual-scoping-channels**: the alternate client's list/mint/revoke operations
  MUST accept scoping through a query-parameter scope channel independently of the
  mint-request body's own ecosystem-id field, a separate channel; that layer
  performs no reconciliation between the two channels — a caller sets whichever one
  the operation needs (mirroring the primary implementation's rail, whose create
  form always leaves the body's ecosystem-id field unset and relies solely on the
  parameter channel).
- **token-created-once**: the created-token result (the response that carries the
  plaintext secret) MUST be a distinct shape from the token list-row shape (which
  carries only a `prefix`); the alternate client gives no other route through which
  the raw secret can be retrieved again.

