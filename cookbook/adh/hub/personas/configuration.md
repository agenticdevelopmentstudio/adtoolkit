
- `dataSource`: the persona data source implementation injected into this domain's navigation
  contract — supplied by the host application, typically backed by its own API client.
- `workspace` (optional, on list/create/update/delete): a workspace slug that scopes the operation
  to that workspace's owning principal instead of the caller's own rows.
- `personaId` / `bucketId` / `typeId` / `rowId`: caller-supplied identifiers threading through the
  interest-documents, special-interests, approvals, may-act, tools, and user-tools operations to
  select which persona's records or grants are being read or changed.
- `kind` (`"user" | "team"` for may-act; `"user" | "team" | "org"` on the wire body): which
  context a persona is granted or denied leave to act under.
- `status` (approvals listing, default `"pending"`): which approval queue state to list.
- Demo-preview payload fields — `source`, `signInLine`, `message`, `history`, `canEscalate` — all
  caller-supplied inputs to one preview call; `canEscalate` selects which visitor's demo (signed-in
  vs. anonymous) is being previewed.
- Each field's wire strategy (`trimRequired` / `trimOptional` / `raw` / `omit`) is compiled into
  the draft-to-payload conversion and is not caller-configurable at runtime.

