
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` | string (caller parameter) | none — required on every call | The workspace slug (personal customer slug or org slug) every call is scoped to; percent-encoded before being placed in the URL. |
| `scope` (list-assignments) | object with `feature` and `itemId` (optional) | omitted → workspace-wide listing | When given, narrows the assignments list to one item; omitted, lists workspace-wide assignments. |
| `input` (create-role) | role write input | none — required | `{ slug, name, description?, defaultFor?, grants }`, sent verbatim as the create-request body. |
| `patch` (update-role) | partial role write input, excluding `slug` | none — required | Any subset of `name`/`description`/`defaultFor`/`grants`; `slug` cannot be supplied. |
| `input` (assignment-upsert) | assignment write input | none — required | `{ subjectKind, subjectId, feature?, itemId?, roleId }`, sent verbatim as the upsert-request body. |
| `q` (effective-access query) | `{ feature, subjectKind, subjectId, itemId? }` | none — required | `itemId` is appended to the query only when provided. |
| base route | fixed constant, `/api/access` | fixed | Not injectable or configurable; every request path is built from it. |
| fallback feature list | fixed, read-only list of feature-area rows | fixed two-entry list | The fallback a caller may use when listing feature areas fails against a backend that predates the features route; not applied automatically by this client. |

