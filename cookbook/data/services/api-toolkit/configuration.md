
- **The API base** (used by request building/execution and by the CRUD
  resource state) — fixed constant `/api`; not caller- or
  environment-configurable in the given source.
- **`token`** (an optional argument to the request builder) — optional,
  caller-supplied bearer token forwarded as `Authorization: Bearer <token>`.
- **The public API origin** (used by snippet generation) — fixed constant
  `https://api.agenticdeveloperhub.com` used only for generated snippet URLs,
  never for the same-origin requests the request builder itself issues.
- **The editability overrides** (used by column editability) — a
  module-level object callers may hand-populate (outside test code) to force
  a non-relational, non-server-managed column's editability; empty by
  default.
- **`meta` / `filter` / `scopeEcosystemId`** (arguments to the CRUD resource
  state) — `meta` (the table's metadata) is required; `filter` is an optional
  caller-supplied query object serialized into the list query; `scopeEcosystemId`
  is an optional caller-supplied scope value that precedes `filter` in the
  query string and rides every verb, not just the list call.
- **`isAdminViewer`** (an argument to the table visibility gate's checks) —
  caller-supplied boolean, typically sourced from the viewer state's admin
  flag.

