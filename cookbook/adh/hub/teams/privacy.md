
- **Data collected**: Team administrative metadata (`displayName`,
  `identifier`) and per-member data — a member's `role`, `addedAt`, and,
  for a customer member, `email`/`displayName` resolved from that
  customer's own row; for a persona member, `personaSlug`/`personaName`.
  `email` is the one field here that directly identifies a person outside
  the platform's own naming.
- **Storage**: This client holds no cache of its own — every call is a
  live round trip through the shared request helper. Whatever caching a
  consumer layers on top is outside this domain's files.
- **Transmission**: Every call travels through the shared
  authenticated-request helper (a Bearer-token client); this domain itself
  attaches no credential and reads no cookie.
- **Retention**: This domain retains nothing between calls; it is a
  stateless set of functions over the network. A removed member or a
  deleted team leaves no trace in this client — retention of the
  underlying rows is a backend concern this domain's files do not
  describe.

