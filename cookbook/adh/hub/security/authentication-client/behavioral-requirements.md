
**Root routing**

- **root-tokens-level**: The root level MUST be titled "Tokens" with exactly three items, in order:
  `"api"` ("API tokens"), `"storage"` ("Storage tokens", with a divider after it), and `"about"` ("About
  tokens"), and MUST set an empty list-empty message and no create action (the level itself offers no
  create action; creation happens one level down, inside each rail).
- **root-path-routing**: Routing a path MUST send a path whose first item's id is `"api"` to the API
  tokens rail with the remaining path, `"storage"` to the storage tokens rail with the remaining path
  and no ecosystem given, and `"about"` with an empty remaining path to a read-only notice detail
  showing the module's overview message; an empty path MUST return the root level itself.
- **root-unknown-routes-empty**: Routing a path MUST return an empty result for any first-item id other
  than `"api"`/`"storage"`/`"about"`, and for `"about"` with a non-empty remaining path.
- **root-storage-uses-personal-scope**: The root's `"storage"` route MUST always route into the storage
  tokens rail with no ecosystem given, so the root "Storage tokens" section lists only the caller's own
  (workspace) storage tokens, never an ecosystem's.

**Personal API tokens**

- **api-tokens-list-sorted-by-name**: The token list MUST be sorted by name using a case-insensitive,
  locale-aware comparison (ascending).
- **api-tokens-list-item-shape**: Each row's identifier MUST be the token's id, its label the token's
  name, its sublabel `"\(prefix)… · \(scopeLine)"`, its icon a key glyph, and it MUST lead to a detail
  view.
- **api-tokens-scope-line-legacy-fallback**: A token's scope line MUST be `"legacy"` when its scope is
  absent or empty, otherwise the scopes joined with `", "`.
- **api-tokens-catalogue-fetched-per-open**: The "New API token" create action MUST fetch the scope
  catalogue fresh every time the create form is opened; it MUST NOT reuse a catalogue fetched by an
  earlier open.
- **api-tokens-catalogue-unavailable-disables-create**: When fetching the scope catalogue fails, the
  create form MUST present exactly one read-only field (labeled "Scope catalogue") and no save action,
  so the form can display an explanatory message but cannot mint a token.
- **api-tokens-create-fields**: The create form MUST present, in order: a required `name` text field, a
  read-only scope-help field, one toggle field per catalogue prefix (labeled with the bare prefix), a
  "Read-only (GET/HEAD only)" toggle, and an expiration date field.
- **api-tokens-empty-scope-rejected**: The create action MUST reject with a validation error naming the
  "choose at least one scope" message when no scope toggle is selected, regardless of the read-only
  toggle's value, and MUST NOT proceed to create the token in that case.
- **api-tokens-scope-derivation**: The derived scope MUST include, in catalogue order, every prefix
  whose toggle is on, each suffixed `":read"` when the read-only toggle is on and left bare otherwise,
  and MUST be considered absent when no prefix toggle is on.
- **api-tokens-name-trimmed**: The create action MUST trim leading/trailing whitespace from the `name`
  field before submitting the create request.
- **api-tokens-reveal-on-create**: On a successful create, the returned plaintext secret MUST be stored
  keyed by the new token's id, for one-time display.
- **api-tokens-reveal-once**: Resolving any path MUST first expire the previously revealed secret unless
  the requested detail's id equals the one currently shown; expiring MUST remove the revealed secret and
  clear the "currently revealed" marker, and MUST leave both untouched when the same detail is
  re-rendered.
- **api-tokens-detail-field-order**: The detail view MUST list read-only fields in the order `name`,
  `prefix`, `scope`, `created`, `lastUsed`, `expires`, followed by the secret and a notice field only
  when a revealed secret exists for that token.
- **api-tokens-detail-fallbacks**: The detail view MUST render `scope` as `"legacy (curated-only)"` when
  the token's scope is absent or empty (else the scopes joined by newlines), `lastUsed` as `"never
  used"` when absent, and `expires` as `"never"` when absent.
- **api-tokens-revoke**: The detail's delete action MUST be titled "Revoke token" with confirmation text
  `Revoke API token "{name}"? Anything using it will stop working.`, MUST revoke the token, and on
  success MUST clear its revealed secret.
- **api-tokens-unknown-path-empty**: Resolving a path MUST return an empty result when the path names
  exactly one segment and no token matches it, and for any path with more than one segment.
- **api-tokens-errors-wrapped**: Every call into the token data source MUST have its errors normalized
  to the single named error type (the create action's own two validation checks above already throw
  that type directly, since creating and revoking are the only throwing operations besides them).

**Storage tokens (shared with a separate ecosystem-configuration feature)**

- **storage-tokens-ecosystem-scoped**: Every storage-tokens operation (listing, level, create form,
  detail) MUST take an optional ecosystem identifier and pass it through unchanged to the underlying
  list/create/revoke calls; absent means the caller's own (workspace) tokens, present means that
  ecosystem's tokens.
- **storage-tokens-list-sorted-by-slug**: The token list MUST be sorted by a raw ordinal comparison on
  slug (NOT a locale-aware comparison, unlike the personal API tokens list's name sort).
- **storage-tokens-list-item-shape**: Each row's label MUST be the token's identifier or, when absent,
  its slug; sublabel `"\(prefix)… · \(bucketRdid ?? "no bucket")"`; icon a drive glyph; and it MUST lead
  to a detail view.
- **storage-tokens-about-varies-by-scope**: The explanatory "about" text MUST vary depending on whether
  an ecosystem was given: one variant when none was given, a different variant when one was; the create
  form's "about" value MUST come from this text.
- **storage-tokens-name-pattern**: The create form's `name` field MUST enforce the shared identifier
  pattern (see Configuration) with its associated violation message.
- **storage-tokens-create-body-shape**: The create action MUST trim the `name` field, MUST pass a
  non-blank version of the `description` field (absent when blank/missing), and MUST leave the request
  body's own `ecosystemId` field unset unconditionally — the actual ecosystem scope is conveyed
  exclusively through the separate ecosystem argument passed alongside the request, never through the
  body's own field.
- **storage-tokens-create-conflict-message**: The create action MUST catch a name-conflict error
  specifically and rethrow it as a validation error naming a "name already taken" message.
- **storage-tokens-create-error-tiering**: The create action MUST rethrow any other error from the named
  error type unchanged, and MUST convert any other kind of failure into an "unexpected" case of the
  named error type carrying a "creation failed" message — a three-way handling distinct from the single
  normalize-and-wrap pattern every other create/update/delete path in this component uses.
- **storage-tokens-reveal-on-create**: On success, the create action MUST store the returned plaintext
  secret keyed by the new token's id, mirroring `api-tokens-reveal-on-create`.
- **storage-tokens-reveal-once**: Resolving any path MUST first expire the previously revealed secret,
  with the same drop/keep semantics as `api-tokens-reveal-once`.
- **storage-tokens-detail-field-order**: The detail view MUST list read-only fields in the order `name`,
  `identifier`, `prefix`, `bucket`, `description`, `created`, `lastUsed`, `expires`, followed by the
  secret/notice fields only when a revealed secret exists.
- **storage-tokens-detail-fallbacks**: The detail view MUST render `name` as the token's slug (not its
  identifier), `identifier` as the token's identifier or an em dash when absent, `bucket` as the bucket
  identifier or `"no bucket"`, and `description` as an em dash when empty.
- **storage-tokens-revoke**: The detail's delete action MUST be titled "Revoke token" with confirmation
  text `Revoke storage token "{slug}"? Anything using it will lose access to its bucket.`, MUST revoke
  the token, and on success MUST clear its revealed secret.
- **storage-tokens-unknown-path-empty**: Resolving a path MUST return an empty result when the path
  names exactly one segment and no token matches, and for any path with more than one segment.

**Access lists**

- **access-topic-entry**: The access lists entry point MUST have identifier `"access"`, label
  `"Access"`, and a lock-shield icon.
- **access-groups-scoped-to-ecosystem**: Resolving any path within this topic MUST filter the fetched
  groups down to those belonging to the given ecosystem before building the list level or resolving the
  first path segment against it.
- **access-groups-sort-order**: The group list MUST be sorted first by the owning bucket's
  case-insensitive, locale-aware name (falling back to the raw bucket identifier when no bucket in the
  supplied bucket list matches), then by whether the group is the built-in "everyone" group (that group
  first within its bucket), then by the group's own case-insensitive, locale-aware name.
- **access-create-requires-bucket**: The "New access list" action MUST reject with a validation error
  (`"Choose a bucket."`) when no bucket is selected.
- **access-create-rejects-duplicate-name-client-side**: The create action MUST reject, before submitting
  the create request, a trimmed name that case-insensitively matches an existing group's name within the
  same bucket, with `An access list named "{name}" already exists in that bucket.`.
- **access-create-conflict-message**: The create action MUST catch a name-conflict error from the create
  request and rethrow it as a validation error (`An access list named "{name}" already exists.`); any
  other error MUST be normalized through the shared error-wrapping.
- **access-group-level-composition**: A group's detail level MUST contain exactly three items —
  `settings` (leads to a detail view), `members` (leads to a list view, sublabel "Applies to everyone"
  for the everyone group else "{N} member(s)"), `grants` (leads to a list view, sublabel "{N}
  grant(s)") — and MUST set an empty list-empty message and no create action.
- **access-everyone-name-locked**: The settings detail MUST render `name` as a non-editable read-only
  field (plus a read-only help note explaining that the built-in "everyone" list applies to every
  principal and can't be renamed) for the everyone group, and as an editable required text field
  otherwise.
- **access-everyone-delete-blocked**: The settings detail MUST omit the delete action and instead append
  a read-only note field explaining that the everyone group can't be deleted, for the everyone group.
- **access-settings-save-name**: The settings save action MUST leave `name` unset when saving the
  everyone group, and otherwise send the trimmed `name` field's value.
- **access-settings-delete**: For a non-everyone group, the delete action MUST be titled "Delete access
  list" with confirmation text `Delete access list "{name}"? Its members and grants will be removed.`
  and MUST delete the group.
- **access-everyone-members-is-notice**: Resolving the `"members"` segment under the everyone group MUST
  return a read-only notice explaining that its membership can't be edited, never the editable members
  level.
- **access-members-list-item-shape**: Each member row's identifier MUST be the member row's id, label
  the member's identifier, sublabel the member type's title, and icon the member type's glyph or a
  question-mark glyph when the type is unrecognized.
- **access-member-type-options**: The "Add member" form's type field MUST offer exactly the member-type
  options, in a fixed order (`user`, `organization`, `persona`, `application`, `token`), each option's
  value being that type's wire value — including `application`, whose wire value is the literal string
  `"app"`, not `"application"`.
- **access-member-add-required-fields**: The "Add member" action MUST reject with a validation error
  (`"Choose a type."`) when the type field doesn't decode to a recognized member type, and MUST trim the
  member-identifier field before submitting.
- **access-member-add-conflict-message**: The add-member action MUST catch a conflict error and rethrow
  it as a validation error (`"That member is already in this access list."`).
- **access-member-remove**: The member detail's delete action MUST be titled "Remove member" with
  confirmation text `Remove {typeTitle} "{memberId}" from this access list?` and MUST remove the member.
- **access-grants-list-item-shape**: Each grant row's label MUST be the resolved target label, and its
  sublabel the grant's permission summary.
- **access-grant-target-label**: The target label MUST be `"Whole bucket"` for a bucket-wide target, the
  matching table's name (or the bare target identifier when no table matches its id) for a bucket-type
  target, `"Row {targetId}"` for a row target, and the bare target identifier when the target is
  unrecognized.
- **access-grant-target-options-shrink**: The "Add grant" form's target field MUST offer `"Whole
  bucket"` only while no existing grant targets the whole bucket; MUST offer `"Bucket type"` only while
  at least one table has no existing grant targeting it; and MUST always offer `"Row"`.
- **access-grant-target-required**: The "Add grant" action MUST reject with a validation error
  (`"Choose a target."`) when the target field doesn't decode to a recognized target type.
- **access-grant-bucket-type-required**: When the target is a bucket type, the action MUST reject with a
  validation error (`"Choose a bucket type."`) when the bucket-type field is blank.
- **access-grant-row-id-required**: When the target is a row, the action MUST trim the row-id field and
  reject with a validation error (`"Enter a row id."`) when the trimmed value is blank.
- **access-grant-row-id-length-limit**: When the target is a row, the action MUST reject with a
  validation error (`"Row id must be 36 characters or fewer."`) when the trimmed row id's length
  (counted in user-perceived characters, not bytes) exceeds 36; a length of exactly 36 MUST be accepted.
- **access-grant-permission-required**: Both the "Add grant" action and an existing grant's "Save"
  action MUST reject with a validation error (`"Choose at least one permission."`) when every
  create/read/update/delete toggle is off.
- **access-grant-save-never-deletes**: Saving an existing grant with every permission toggle off MUST
  NOT delete the grant (MUST reject with `access-grant-permission-required`'s error instead); a grant
  MUST be removable only through its own "Remove grant" action.
- **access-grant-remove**: The grant detail's delete action MUST be titled "Remove grant" with
  confirmation text `Remove the grant for {label}?` and MUST remove the grant.
- **access-grant-unknown-target-blocked-on-save**: Saving an existing grant whose target is unrecognized
  MUST reject with a validation error (`Unknown grant target "{targetType}".`) rather than attempting to
  save it.
- **access-crud-serialization**: The permission set MUST serialize as a comma-separated, upper-case
  subset of `"C"`,`"R"`,`"U"`,`"D"` in that fixed order (only the granted permissions present, `""` when
  none); parsing MUST read a comma-separated string case-insensitively, trimming whitespace around each
  token.
- **access-unknown-path-empty**: Resolving a path MUST return an empty result for any group id, second
  path segment, or member/grant row id that doesn't match the currently fetched
  groups/detail/members/grants.
- **access-detail-refetches-every-call**: Resolving a path MUST re-fetch the bucket list, the group
  list, and — whenever the path is non-empty — the group detail and bucket-table list on every call;
  the four MUST NOT be cached across calls.

**Shared across all four roles**

- **error-domain-is-hub-error**: Every one of the four roles MUST surface only the shared named error
  type to its caller; the root module, API tokens rail, and access lists topic achieve this by
  normalizing every data-source error through the shared error-wrapping helper, while the storage tokens
  rail's create path uses the three-way handling in `storage-tokens-create-error-tiering` instead — that
  divergence is intentional and MUST be preserved, not unified, when this component is ported or
  refactored.

**Security**

- **security-secret-not-persisted**: Each rail MUST NOT write a revealed plaintext secret to disk, to a
  settings store, or to a secure credential store; the revealed-secrets store is a plain in-memory
  mapping with no backing store.
- **security-secret-single-source**: The plaintext secret MUST be obtainable only from the response of
  the create call; no operation in this contract re-fetches or re-derives a previously issued secret
  once its reveal has expired (`api-tokens-reveal-once` / `storage-tokens-reveal-once`).
- **security-unauthorized-propagates**: An unauthorized or forbidden error thrown by any data source
  MUST propagate unchanged to the caller through the shared error-wrapping helper rather than being
  caught, retried, or downgraded locally.
- **security-revocation-is-the-response**: The only way this component withdraws a previously granted
  credential or permission is outright removal — revoking a token, or removing a member/grant for
  access — MUST NOT offer any "soft-disable" or partial-trust intermediate state.

