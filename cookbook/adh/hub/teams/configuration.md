
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` (listing/creating a team) | `string` | required, no default | Scopes the op to that ecosystem's own teams via `?ecosystemId=` |
| `id` (fetching/updating/deleting a team) | `string` | required, no default | The team row's opaque server-generated id |
| `input.displayName`/`input.identifier` (creating a team) | `string`/`string` | required, no default | Sent as backend `name`/`slug` |
| `input` (updating a team) | partial team-input object | `{}` (all fields optional) | Only defined keys are sent, via the shared field-compaction helper |
| `teamId` (listing/adding members) | `string` | required, no default | The team a member list is read from or added to |
| `email` (adding a member by email) | `string` | required, no default | Resolved to an existing customer within the caller's ecosystem |
| `personaKey` (adding a member by persona) | `string` | required, no default | One of the caller's own personas; gated on its "team" action-permission grant |
| `memberId` (removing a member) | `string` | required, no default | The membership row's own id |

