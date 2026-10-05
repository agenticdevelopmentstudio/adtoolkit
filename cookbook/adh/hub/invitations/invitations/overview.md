
This is a `logic`-root component with no visual surface of its own: it is
the Invitations domain's data shapes, its three admin-facing HTDV topic
providers, their shared admin-notes sub-rail, and the web data client a
registering recipient uses. The two sides describe two different actors
looking at the same domain, not two ports of one feature:

- **Apple (admin side)**: `RequestsTopic`, `PendingUsersTopic`, and
  `InvitesTopic` are UI-thread-confined `EcosystemTopicProvider`s that let a Hub
  admin browse and act on `InvitationRequest`s (a prospective user asking to
  join), `PendingUser`s (an admin-created draft awaiting an invite send), and
  `Invite`s (an invite that has already been sent). All three attach the same
  `AdminNotesRail` — a shared per-subject notes sub-rail — as a child level,
  and all three read and write through one injected `InvitationsDataSource`.
- **Web (recipient side)**: `invitationsApi` (`invitations.ts`, with wire
  types in `wire.ts`) is the client a recipient's browser calls when they
  open an invite link: `preview` (what ecosystem, without authenticating),
  `verify` (is this specific code still valid), `accept` (an already
  signed-in user joins), and `registerWithInvite` (a new user creates an
  account from the invite in one call). Nothing here is admin-facing, and
  nothing here is a client for `InvitationsDataSource`'s admin operations —
  the two sides never call into each other.

