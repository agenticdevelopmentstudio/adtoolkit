
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `entityNoun` | string | — | Singular entity noun (e.g. "Persona"), used verbatim in the button and dialog title, and lowercased for inline prose ("Move this persona…") and the token-count/error fallback text |
| `entityLabel` | string | — | The object's own identifier; shown in the dialog and retyped (trimmed) to arm the Transfer button |
| `targets` | list of destination targets | — | Candidate destinations; team workspaces must already be filtered out by the caller |
| `currentTarget` | destination target reference (optional) | `undefined` | The destination the object already lives in; shown disabled in the menu |
| `onPreview` | function taking a destination target, returning a transfer preview result | — | Server preflight; its result populates the dialog, a rejection shows an inline error |
| `onConfirm` | function taking a destination target, returning nothing (asynchronously) | — | Performs the transfer; a rejection shows an inline error and keeps the dialog open |

### Data Model

- **Destination target**: fields `slug`, `kind` (optional — `"customer"` or `"organization"`),
  `name`, and `children` (optional list of destination targets). `kind` is omitted only for a
  target that is not a workspace — a nested Product, whose `slug` is already globally unique. A
  non-empty `children` list makes the entry render as a submenu of its own child targets.
- **Destination target reference**: the subset of a destination target's fields needed to
  identify one — `slug` and `kind` — used for `currentTarget`.
- **Transfer preview result**: fields `tokens` (a count) and `revoking` (a list of entries, each
  with `kind` — one of `"user"`, `"team"`, `"persona"`, `"organization"`, `"app"`, `"token"` —
  `id`, `name`, and `via` — one of `"role"`, `"team"`, `"direct"`, `"participant"`, `"group"`).
  `tokens` is the count of API tokens bound to the object that will be revoked. Each `revoking`
  entry is one principal that will lose access, its `kind`, and `via` — how it currently has access
  (a direct grant, a role, team membership, participant seat, or access-group membership).

