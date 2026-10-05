
### Cross-cutting

- **ui-context-confinement**: the three topic providers and the notes rail are bound to the UI's
  serial execution context; every method on all four runs there, and none is shared across
  execution contexts, so every instance stays confined to that context.
- **data-source-is-reference-semantics**: the invitations data source has reference semantics, so
  an injected implementation is a shared, stateful client; all three topics and the notes rail hold
  it by reference and never copy it.
- **missing-row-yields-empty**: For every one of the three topics, when
  `path.last` (via `RailPath.last`) does not match any row currently held by
  the topic's own last-loaded list, `detail(for:in:)` (or, for
  `PendingUsersTopic`, `inviteDetail(for:in:)`) returns `.empty` rather than
  throwing.
- **errors-wrap-through-hub-error**: Every asynchronous, fallible entry point on all three topics
  and on the notes rail wraps a caught error with `HubError.wrap` before rethrowing or surfacing it
  as a form's save error, so a caller only ever observes `HubError` cases from this domain, never the
  underlying data source error type directly.
- **notes-rail-shared-across-subjects**: `AdminNotesRail` is not itself an
  `EcosystemTopicProvider` — it is a value type each of the three topics
  constructs identically (same `dataSource`, same `ecosystemID`) and attaches
  as a child level keyed by an `AdminNoteSubject` case (`.request`, `.pendingUser`,
  or `.invite`) plus the subject's own id, so the same notes UI and the same
  create/edit/delete behavior back every subject kind without three separate
  implementations.

### InvitationsModels.swift — data shapes

- **invitation-request-shape**: `InvitationRequest` carries `id`, `name`,
  `email: String?`, `phone: String?`, `message: String?`, `requestedAt`,
  `status`, matching what `RequestsTopic` renders.
- **request-contact-derivation**: `InvitationRequest.contact` returns `email`
  if non-blank (via `HubText.nonBlank`), else `phone` if non-blank, else the
  literal string `"—"` — email is preferred over phone whenever both are
  present.
- **pending-user-shape**: `PendingUser` carries `id`, `name`, `email: String?`,
  `phone: String?`, `note: String?`, `createdAt`, `invitedAt: String?`.
- **pending-user-contact-derivation**: `PendingUser.contact` uses the same
  email-else-phone-else-`"—"` fallback as `InvitationRequest.contact`.
- **invite-shape**: `Invite` carries `id`, `name`, `channel` (a raw string,
  e.g. `"email"` or `"sms"`), `destination`, `sentAt`, `status`.
- **invite-channel-title-derivation**: `Invite.channelTitle` maps
  `channel == "email"` to `"Email"`, `channel == "sms"` to `"Text message"`,
  and any other raw value to that raw value unchanged — an unrecognized
  channel is displayed verbatim rather than mapped to a placeholder.
- **draft-user-shape**: `DraftUser` (the write-side counterpart of
  `PendingUser`) carries `name`, `email: String?`, `phone: String?`,
  `note: String?` and is the payload `addPendingUsers` accepts.
- **invitation-channel-note-shape**: `InvitationChannelNote` pairs a
  `channel` string with a `note: String?`, used inside `InvitationSend`.
- **invitation-send-shape**: `InvitationSend` carries `channels:
  [InvitationChannelNote]` (one entry per channel the admin chose to send
  on) and is the payload `sendInvitation` accepts.
- **admin-note-shape**: `AdminNote` carries `id`, `content`, `createdBy:
  String?`, `createdAt` — the read-side shape returned by
  `InvitationsDataSource.notes`.
- **admin-note-headline-derivation**: `AdminNote.headline` splits `content`
  on newlines and returns the first line that is not blank (via
  `HubText.nonBlank`), or the literal string `"(empty note)"` if every line
  is blank or `content` is empty.
- **admin-note-input-shape**: `AdminNoteInput` carries `id: String?`
  (defaulting to `nil` for a new note) and `content`, and is the payload
  `AdminNotesRail.rewrite` sends back to
  `InvitationsDataSource.replaceNotes`.
- **admin-note-to-input-projection**: `AdminNote.input` projects an
  `AdminNote` down to the `AdminNoteInput` `rewrite` needs to round-trip it
  (`id` and `content` only — `createdBy` and `createdAt` are dropped, since
  the write side never sets or changes who authored a note or when).
- **history-entry-shape**: `HistoryEntry` carries `id`, `actorId: String?`,
  `action`, `occurredAt`.
- **history-entry-line-derivation**: `AdminNotesRail.historyText(_:)` renders
  one line per `HistoryEntry` as `"<action> by <actor> on <date>"`, using
  `entry.actorId` if non-blank else the literal string `"system"` for
  `<actor>`, and `HubDates.display(entry.occurredAt)` for `<date>`; an empty
  history array renders as the single literal string `"No history."` rather
  than an empty string.
- **admin-note-subject-enum**: `AdminNoteSubject` is a `.request`,
  `.pendingUser`, or `.invite` case used to scope every `InvitationsDataSource`
  notes/history call and every `AdminNotesRail` HTDV path segment to the
  correct subject kind and id.
- **data-source-contract**: the invitations data source declares eleven asynchronous, fallible
  operations: `requests`, `deleteRequest`, `pendingUsers`, `addPendingUsers`, `deletePendingUser`,
  `sendInvitation`, `invites`, `deleteInvite`, `notes`, `replaceNotes`, `history` — every one scoped
  by `ecosystemID` and, where applicable, by `AdminNoteSubject` and a subject id.

### AdminNotesRail.swift — shared admin-notes sub-rail

- **notes-rail-identity**: `AdminNotesRail.item` is a fixed `HTDVItem` (a
  constant "Notes" navigation entry) that all three topics attach identically
  as the notes child level under a subject's detail.
- **notes-level-shape**: The notes level lists every `AdminNote` for the
  subject via `dataSource.notes(...)`, rendering `note.headline` as each
  row's title, offers a `createAction` labeled `"New note"`, and shows the
  literal empty-state message `"No notes yet."` when the list is empty.
- **notes-detail-dispatch**: `AdminNotesRail.child(path:)` resolves the last
  path segment to a note id, looks that id up in the freshly-loaded notes
  list, and calls `noteDetail(_:)` on a match; on no match it returns
  `.empty` per **missing-row-yields-empty**.
- **notes-create-spec-shape**: The create `FormSpec` has one required
  text-area field keyed `"content"` (blank content produces the Forms
  built-in required-field error), and its save action appends a new
  `AdminNoteInput(id: nil, content: <value>)` to the subject's current notes
  via `rewrite`.
- **notes-detail-spec-shape**: The note-detail `FormSpec` has the same
  required `"content"` field pre-filled with the note's own content, plus a
  read-only `"author"` field showing `note.createdBy` for display only (the
  save action never sends `createdBy` back, so editing this field has no
  effect); saving maps every one of the subject's current notes through
  `rewrite`, replacing only the entry whose `id == note.id` with the edited
  content, and its delete action filters that one note out by id.
- **notes-rewrite-is-read-then-overwrite**: the notes rail's `rewrite` is a pure-static helper
  taking the data source, ecosystem id, subject, subject id, and a transform function as explicit
  parameters rather than capturing the rail; it fetches the subject's current notes (projected to
  note inputs), applies the transform to build the full replacement list, and calls
  `dataSource.replaceNotes(...)` with that entire list — every write replaces the whole note
  collection for that subject, not just the one changed note.
- **notes-errors-wrapped**: Every `AdminNotesRail` entry point that can throw
  wraps the underlying error with `HubError.wrap` before it reaches the
  caller, per **errors-wrap-through-hub-error**.

### RequestsTopic.swift

- **requests-topic-identity**: `RequestsTopic` is an `EcosystemTopicProvider`
  constructed with an `InvitationsDataSource` and an `ecosystemID`, backing a
  rail that lists `InvitationRequest`s.
- **requests-list-shape**: The top-level list loads via
  `dataSource.requests(ecosystemID:)`, renders each row's `name` and
  `contact`, and offers no `createAction` — a request is created by the
  prospective user, not by an admin from this rail.
- **requests-detail-nav**: A request's detail level has two children: its
  own `FormDetails` (fields) and the shared `AdminNotesRail` notes level
  scoped to `.request` and the request's id.
- **requests-detail-shape**: The detail form renders read-only fields for
  `name`, `email` (or `"—"` if blank), `phone` (or `"—"` if blank), `message`
  (or `"—"` if blank), `requestedAt` via `HubDates.display`, `status`, and a
  `"history"` field rendering `AdminNotesRail.historyText` over
  `dataSource.history(...)` for `.request`.
- **requests-delete-shape**: The detail's `FormDeleteAction` asks for
  confirmation, then calls `dataSource.deleteRequest(ecosystemID:id:)`.
- **requests-errors-wrapped**: `RequestsTopic`'s list load, detail load, and
  delete all wrap thrown errors per **errors-wrap-through-hub-error**.

### PendingUsersTopic.swift

- **pending-users-topic-identity**: `PendingUsersTopic` is an
  `EcosystemTopicProvider` backing a rail that lists `PendingUser`s.
- **pending-users-list-shape**: The top-level list loads via
  `dataSource.pendingUsers(ecosystemID:)`, renders each row's `name` and
  `contact`, and offers a `createAction` labeled `"Add users"` that opens the
  add-users spec.
- **add-users-spec-contact-requirement**: The add-users `FormSpec` requires a
  non-blank `"name"` field (Forms' built-in required-field message), and its
  save action rejects the submission with `PendingUsersTopic.contactMessage`
  (the literal string `"Enter an email address or a phone number."`) unless
  at least one of `"email"` or `"phone"` is non-blank; when the check passes
  it calls `dataSource.addPendingUsers(ecosystemID:_:)` with one
  `DraftUser` built from the form's `name`, `email`, `phone`, and `note`
  values.
- **add-users-spec-shared-email-pattern**: The add-users spec's `"email"`
  field reuses `CustomersTopic.emailPattern` and `CustomersTopic.emailMessage`
  directly (from the Customers domain) rather than defining its own email
  pattern and message, so the two domains validate an email address
  identically.
- **pending-user-detail-nav**: A pending user's detail level has three
  children: its own `FormDetails`, an `"invite"` level that opens the
  send-invitation spec, and the shared `AdminNotesRail` notes level scoped to
  `.pendingUser` and the pending user's id.
- **pending-user-detail-shape**: The detail form renders read-only fields for
  `name`, `email` (or `"—"`), `phone` (or `"—"`), `note` (or `"—"`),
  `createdAt` via `HubDates.display`, and `invitedAt` via `HubDates.display`
  (or the fallback `"—"` when `invitedAt` is `nil`).
- **pending-user-delete-shape**: The detail's `FormDeleteAction` asks for
  confirmation, then calls
  `dataSource.deletePendingUser(ecosystemID:id:)`.
- **send-invitation-detail-defaults**: `PendingUsersTopic.inviteDetail(for:in:)`
  is synchronous and non-throwing (unlike every other detail accessor in this
  domain); its `FormSpec` offers one toggle per available channel (email,
  sms), each toggle defaulting to `true` exactly when the pending user's own
  `contact` supplies that channel (e.g. the sms toggle defaults to `true`
  only when `phone` is non-blank) and to `false` otherwise, plus a
  free-text `"note"` field per channel.
- **send-invitation-validation**: The send-invitation save action rejects the
  submission with the literal string `"Choose at least one channel."` if
  every toggle is off; if a toggle for a channel the user has no contact
  value for is turned on, it rejects with a channel-specific literal message
  (e.g. `"This user has no phone number."` for sms with no `phone`).
- **send-invitation-payload-shape**: On success, the save action builds an
  `InvitationSend` with one `InvitationChannelNote` per checked toggle
  (carrying that channel's note field, or `nil` if left blank) and calls
  `dataSource.sendInvitation(ecosystemID:_:)`.
- **pending-users-errors-wrapped**: `PendingUsersTopic`'s list load, detail
  load, and delete wrap thrown errors per
  **errors-wrap-through-hub-error**; `inviteDetail` itself cannot throw (it
  builds a form spec synchronously from data already in memory), so only its
  save action's own `dataSource.sendInvitation` call is subject to wrapping.

### InvitesTopic.swift

- **invites-topic-identity**: `InvitesTopic` is an `EcosystemTopicProvider`
  backing a rail that lists `Invite`s already sent.
- **invites-list-shape**: The top-level list loads via
  `dataSource.invites(ecosystemID:)`, renders each row's `name` and
  `channelTitle`, and offers no `createAction` — an invite is created by
  sending one from a pending user, not directly from this rail.
- **invite-detail-nav**: An invite's detail level has two children: its own
  `FormDetails` and the shared `AdminNotesRail` notes level scoped to
  `.invite` and the invite's id.
- **invite-detail-shape**: The detail form renders read-only fields for
  `name`, `channelTitle` (per **invite-channel-title-derivation**),
  `destination`, `sentAt` via `HubDates.display`, and `status`.
- **invite-delete-shape**: The detail's `FormDeleteAction` asks for
  confirmation, then calls `dataSource.deleteInvite(ecosystemID:id:)`.
- **invites-errors-wrapped**: `InvitesTopic`'s list load, detail load, and
  delete all wrap thrown errors per **errors-wrap-through-hub-error**.

### invitations.ts / wire.ts — recipient-facing acceptance client (web)

- **invitations-api-shape**: `invitationsApi` exposes four methods —
  `preview(token)`, `verify(token, code)`, `accept(token)`,
  `registerWithInvite(token, input)` — each returning a `Promise` of its own
  wire row type from `wire.ts`.
- **preview-is-anonymous-and-folds-failure**: `preview` issues an
  unauthenticated `fetch` (`cache: "no-store"`) to
  `/api/public/invitations/preview`, and its own doc comment states it
  "Never throws": on `!res.ok` it resolves to `{ state: "invalid",
  ecosystemName: null, maskedDestination: null }` rather than rejecting;
  only on a `res.ok` response does it parse and return the body as an
  `InvitePreview`.
- **preview-network-failure-rejects**: `preview`'s own doc comment declares it "Never throws," but
  the `fetch` call itself is not wrapped in a try/catch, so a network-level failure (offline, DNS
  failure, request timeout) MUST be understood to reject the returned promise instead of resolving
  to the documented `invalid` state; only HTTP-status failures (`!res.ok`) fold into the `invalid`
  result.
- **verify-is-anonymous-and-throws-status-code**: `verify` issues an
  unauthenticated `fetch` POSTing `{ code }` to a token-scoped verify route;
  on `!res.ok` it throws `Error(String(res.status))` — the thrown message is
  the raw numeric HTTP status as a string, with no call to
  `extractErrorMessage` and no other message-extraction attempt.
- **accept-is-authenticated**: `accept` calls `authedJson` to POST `{
  token }` to an accept route as the signed-in caller, so its authentication,
  one-refresh-then-retry-on-401, and `AuthHttpError` behavior on failure are
  entirely `authedJson`'s (documented in `adtoolkit://cookbook/adh/hub/security/authentication-client`),
  not redefined here.
- **register-with-invite-extracts-message**: `registerWithInvite` issues an
  unauthenticated `fetch` POSTing the full `RegisterWithInviteInput` (`email`,
  `password`, `name`, `invite`) to a registration route; on `!res.ok` it reads
  the response body and throws `Error(extractErrorMessage(body,
  \`Registration failed (${res.status})\`))`, so the thrown message favors a
  server-supplied `error`/`message`/RFC 9457 `detail` field and falls back to
  the literal template `"Registration failed (<status>)"` only when none is
  present.
- **wire-types-mirror-response-shape**: `InvitePreviewRow`, `VerifyResultRow`,
  `AcceptResultRow`, and `RegisterWithInviteResultRow` each declare exactly
  the fields their corresponding endpoint returns, with no client-side
  renaming or derived fields — the wire types are a direct typed mirror of
  the JSON each route sends.
- **user-row-reuses-me-row**: `wire.ts` defines `UserRow` as a type alias for
  `MeRow` (imported from `../personas/wire`) rather than declaring a second,
  separately-maintained shape for the user object embedded in
  `RegisterWithInviteResultRow`.
- **token-and-password-handling**: `RegisterWithInviteInput.password` and
  `RegisterWithInviteResultRow.token`/`refreshToken` pass through
  `invitations.ts` and `wire.ts` only as request/response payload fields —
  neither file persists, logs, or otherwise inspects any of the three
  values; both files hand the parsed response back to their caller
  unmodified, and it is that caller's own token store (not among these
  given sources) that decides how `token` and `refreshToken` are kept,
  how long they last, and how they are revoked.

