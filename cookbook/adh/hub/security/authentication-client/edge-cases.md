
- **Empty lists**: an empty list of tokens or access lists MUST render the rail's empty message ("No
  API tokens yet.", "No tokens yet.", "No access lists yet.") rather than an error.
- **Row id exactly at the boundary**: a trimmed grant row id of exactly 36 characters MUST be accepted;
  37 characters MUST be rejected (`access-grant-row-id-length-limit`).
- **All-CRUD-false on create vs. on an existing grant**: both paths MUST reject identically
  (`access-grant-permission-required`); the existing-grant path additionally MUST NOT treat the
  all-false state as an implicit delete (`access-grant-save-never-deletes`) — a fixed regression the
  source's own comment documents ("Save with every toggle off used to DELETE the grant, silently and
  with no confirmation").
- **Scope catalogue unavailable at create time**: the API tokens rail MUST disable create entirely
  (`api-tokens-catalogue-unavailable-disables-create`) rather than falling back to an unscoped/legacy
  token, because an absent scope selection is itself the broad-legacy-token footgun the disable exists
  to prevent.
- **Scope catalogue available but nothing selected**: MUST be rejected the same way as an unavailable
  catalogue (`api-tokens-empty-scope-rejected`) — for the same reason: an empty selection would silently
  mint the broadest possible token.
- **Concurrent duplicate-name creation (two clients, same bucket)**:
  `access-create-rejects-duplicate-name-client-side`'s pre-check only sees the snapshot of existing
  groups the caller supplied when it built the form; two concurrent creates racing past that check both
  reach the create request, and the loser is caught by `access-create-conflict-message`'s server-side
  conflict handling — the client-side check is an early UX shortcut, not the actual concurrency guard.
- **Everyone group protections apply narrowly**: only `name` (rename) and delete are blocked for the
  everyone group (`access-everyone-name-locked`, `access-everyone-delete-blocked`); its `description`
  remains editable, and its grants/members-viewing (but not members-editing,
  `access-everyone-members-is-notice`) remain reachable like any other group.
- **`lastUsed`/`expires` double fallback**: when the field itself is absent, both rails show "never
  used"/"never"; when the field is present but an unparseable date string, the shared date-formatting
  fallback ("—") applies instead — two different fallback strings reachable from the same field
  depending on which condition holds.
- **Parsing a permission string with garbage input**: an input string like `"x,y,z"` (no recognized
  letters) MUST NOT throw; it parses to a fully-ungranted permission set, since parsing is a
  case-insensitive substring match against `{"C","R","U","D"}` with no validation that every token is
  recognized.
- **A member with an unrecognized type string**: the member's type MUST resolve to an unrecognized type,
  falling back to the raw string for its title; its row falls back to a question-mark glyph.
- **A grant with an unrecognized target type**: the grant's target MUST resolve to an unrecognized
  target; the target label falls back to the bare target identifier, and the grant detail's own target
  line falls back to `"{targetType} · {targetId}"` — a different fallback string from the list label's,
  since the two format the unknown case independently. Saving that grant MUST throw
  `access-grant-unknown-target-blocked-on-save`'s error rather than silently saving it.
- **Member id / row id with no client-side format validation**: the "Add member" form's identifier
  field accepts any non-blank, trimmed string with no pattern check (unlike the storage tokens rail's
  pattern-validated `name`); member identifiers are caller-supplied external ids (user/org/persona/app/
  token ids), not an identifier this component mints.
- **Offline or transport failure from any data source**: every operation propagates the resulting
  offline or transport failure unchanged (through the shared error-wrapping helper, or, for the storage
  tokens rail's create path, through the "any other error" branch of
  `storage-tokens-create-error-tiering`); none of the four roles retries, queues, or caches a request to
  paper over a failure — a failed resolution simply throws, and the caller decides whether to retry.

