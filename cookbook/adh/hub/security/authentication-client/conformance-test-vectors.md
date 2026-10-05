
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| auth-client-001 | root-tokens-level, root-path-routing | Resolving an empty path on the root module | A level titled "Tokens" with items `api`, `storage`, `about` in that order |
| auth-client-002 | root-storage-uses-personal-scope | Resolving the `storage` path segment against a data source that records calls | The list call is observed with no ecosystem given |
| auth-client-003 | root-unknown-routes-empty | Resolving a path whose first segment is `bogus` | An empty result |
| auth-client-004 | api-tokens-empty-scope-rejected | Invoking the create action with every scope toggle off and the read-only toggle on | Throws a validation error naming the "choose at least one scope" message; the create request is never sent |
| auth-client-005 | api-tokens-scope-derivation | The same create action with the `read` scope toggle on and the read-only toggle on | The derived scope is `["read:read"]` |
| auth-client-006 | api-tokens-catalogue-unavailable-disables-create | The scope catalogue fetch fails; the create form is built anyway | The returned form has one read-only notice field and no save action |
| auth-client-007 | api-tokens-reveal-on-create, api-tokens-detail-field-order | A create succeeds returning secret `"tmp_abc"`, then its detail is rendered | Detail includes the secret `"tmp_abc"` and a reveal notice |
| auth-client-008 | api-tokens-reveal-once | After 007, a different token's detail is resolved | The revealed secret for the created token is removed; a later rendering of its detail shows no secret/notice field |
| auth-client-009 | api-tokens-reveal-once | After 007, the same token's detail is resolved again | The revealed secret is unchanged; the secret is still shown |
| auth-client-010 | api-tokens-revoke | The delete action is invoked for a token whose secret is currently revealed | The token is revoked; its revealed secret is cleared afterward |
| auth-client-011 | storage-tokens-name-pattern | The create form's `name` field validated with input `"My Token!"` | Field rejected with the shared pattern's violation message |
| auth-client-012 | storage-tokens-create-conflict-message | The create request fails with a name-conflict error | The create action throws a validation error naming the "name already taken" message |
| auth-client-013 | storage-tokens-create-error-tiering | The create request fails with an unrelated, non-domain error | The create action throws an "unexpected" error naming a "creation failed" message |
| auth-client-014 | storage-tokens-list-sorted-by-slug | Tokens with slugs `["zeta", "alpha"]` and names that would sort oppositely under a locale-aware comparison | The list appears in raw slug order: `alpha`, `zeta` |
| auth-client-015 | storage-tokens-about-varies-by-scope | The "about" text requested with no ecosystem given, versus with ecosystem `"eco-1"` given | The "no ecosystem" variant versus the "with ecosystem" variant respectively |
| auth-client-016 | storage-tokens-create-body-shape | The create action invoked with ecosystem `"eco-1"` given and a description of only whitespace | The request body's `description` is absent; its `ecosystemId` field is unset; the create call is still made with `"eco-1"` as the separate ecosystem argument |
| auth-client-017 | access-groups-scoped-to-ecosystem | Groups fetched for two ecosystems; resolving an empty path scoped to ecosystem A | The resulting list includes only ecosystem A's groups |
| auth-client-018 | access-groups-sort-order | Two groups in the same bucket, one the everyone group and one a custom group, both alphabetically after other-bucket groups | The everyone group's row precedes the custom group's row within that bucket |
| auth-client-019 | access-create-rejects-duplicate-name-client-side | The create action invoked with name `"Editors"` while an existing group named `"editors"` (different case) already exists in the same bucket | Throws a validation error with the "already exists in that bucket" message; the create request is never sent |
| auth-client-020 | access-everyone-name-locked, access-everyone-delete-blocked | The settings detail rendered for the everyone group | The `name` field is read-only; no delete action is present; a note field explains the group can't be deleted |
| auth-client-021 | access-everyone-members-is-notice | Resolving the `"members"` segment under the everyone group | A read-only notice explaining membership can't be edited, with no save/delete actions |
| auth-client-022 | access-member-type-options | The "Add member" form's type field options | Values in order: `"user"`, `"organization"`, `"persona"`, `"app"`, `"token"` |
| auth-client-023 | access-member-add-conflict-message | Adding a member fails with a conflict error | The add action throws a validation error (`"That member is already in this access list."`) |
| auth-client-024 | access-grant-target-options-shrink | Existing grants already include a whole-bucket grant and a bucket-type grant for every table | The "Add grant" form's target options contain only `"Row"` |
| auth-client-025 | access-grant-row-id-length-limit | The action invoked with target `"row"` and a trimmed row id of exactly 36 characters, then 37 characters | The 36-character id is accepted (the save proceeds); the 37-character id throws a validation error (`"Row id must be 36 characters or fewer."`) |
| auth-client-026 | access-grant-permission-required, access-grant-save-never-deletes | An existing grant's "Save" action invoked with all four permission toggles off | Throws a validation error (`"Choose at least one permission."`); the grant is neither saved nor removed |
| auth-client-027 | access-crud-serialization | Serializing a permission set with create and update granted, read and delete not; parsing the string `" r , c "` | Serializes to `"C,U"`; parsing yields a permission set with read and create granted, update and delete not |
| auth-client-028 | access-grant-target-label | Resolving the target label for a bucket-type grant with an unrecognized target identifier against an empty table list | Returns the bare target identifier (no table matched) |
| auth-client-029 | access-detail-refetches-every-call | Two consecutive resolutions of the same group's path against a data source that changes its detail response between calls | The second call's group level reflects the changed response, proving no caching |

