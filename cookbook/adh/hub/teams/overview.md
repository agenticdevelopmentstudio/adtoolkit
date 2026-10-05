
This is the Teams domain: the non-UI logic for a *team* (a named group
owned by an ecosystem) and its membership. There is no separate
implementation for another platform — this is a single reference
implementation split across two clients that sit on two different kinds of
backend route:

- a **team client** — provides mapping and validation helpers plus CRUD.
  The team row itself is generic CRUD, so this client's whole job is
  translating between the backend's column names and the UI's vocabulary
  and scoping every request to the calling workspace's owning ecosystem.
- a **team-membership client** — membership is a hand-written backend
  route (`/api/team/members`, "off generic CRUD"), off the generated
  OpenAPI surface, because a member is one of two different kinds of
  thing — an existing customer added by email, or one of the caller's
  personas added by a grant-gated key — and no generic CRUD table models
  that choice.
- a **shared wire-shapes module** — the backend row and request-body
  shapes the team client's mapper and call sites read and write; type-only,
  and deliberately narrower than the hub's generated success/request-body
  wrappers so this client does not take on "adh product vocabulary a
  generic data client must not take on" (the source's own header comment).
- a **public surface** — re-exports both clients' exports.

Both clients share the transport and shaping conventions documented once
here: a shared authenticated-request helper (a Bearer-token client) throws
an error carrying the backend's message on failure, and every method here
lets that error propagate to the caller except the team client's
single-item fetch, which resolves to `null` instead. A shared
field-compaction helper drops only `undefined` keys from a PATCH/PUT body,
preserving an explicit `null`.

