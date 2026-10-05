
- **Null/empty input**: An empty `identifier` MUST be refused with
  `"Identifier is required."` (MUST, `identifier-validation-empty-refused`).
  Neither adding a member by email's `email` nor adding a member by
  persona key's `personaKey` is validated client-side; an empty value is
  sent to the backend unchanged, and whatever the backend does with it (a
  404 or 400) is this client's behavior too — an absent client-side
  check, not a swallowed error (no documented contract promises one).
- **Boundary/malformed values**: Validating a team identifier MUST accept
  the minimal two-label form (`"a.b"`) and MUST reject a single label
  (`"platform"`, confirmed by Conformance Test Vector 003) — the pattern
  requires at least one dot-separated segment after the first label.
- **Concurrent access**: Two closely-timed create/update calls for the
  same owner/slug MUST leave exactly one team row and MUST present the
  second caller with the friendly "already exists" error via the shared
  conflict-translation helper (`team-create-conflict-rethrown-friendly`,
  `team-update-conflict-rethrown-friendly`). Two closely-timed add-member
  calls adding the same customer to the same team MUST leave exactly one
  member row, but — unlike the team client — the second caller sees the
  backend's RAW conflict message, with no friendly-message mapping
  applied by this client (`member-add-duplicate-is-conflict`).
- **Error states**: Fetching a single team by id resolves ANY thrown error
  to `null`, not only a 404 (see `team-get-swallows-any-error-as-not-found`
  in Behavioral Requirements). Every other method on both clients (listing/
  create/update/delete for teams, all of the team-membership client) lets
  a thrown error propagate unchanged to the caller
  (`member-errors-propagate-with-backend-message`).
- **Offline/disconnected state**: Neither client implements a timeout,
  retry, backoff, or offline queue; a network failure mid-request surfaces
  identically to any other thrown error — an error with no status —
  through the shared request helper, with no built-in recovery in this
  domain's own files (an absent feature, not a swallowed signal, since no
  documented contract in this domain promises retry behavior).

