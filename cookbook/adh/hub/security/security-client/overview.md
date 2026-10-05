
Two independent, unrelated-at-runtime clients that happen to share one surface because both guard
access to backend resources: a **personal API tokens client** mints, lists, and revokes the caller's
own personal API tokens against `/api/auth/tokens`. A **bucket access lists client** is, per its own
documentation, "wired to the real backend access-group routes": CRUD for bucket-scoped access lists (a
named group of principals plus CRUD grants per target), their members, and their grants, against
`/api/bucket/access-groups` and `/api/bucket/buckets/{bucketId}/access-groups`. A shared wire-shapes
module holds the wire shapes for both; per its own header comment it is a local mirror of the backend's
OpenAPI-generated shapes (for `/auth/tokens` and `/bucket/{access-groups,buckets}/*`), carrying full
backend-schema fidelity so this component stays decoupled from the backend's generated types. Both
clients are thin request builders over shared authenticated-request helpers, plus shared
encoding/compaction helpers. Neither client is a visual surface — this is a headless **logic** module,
so this recipe marks Appearance, States, and Accessibility not applicable and carries the runtime
contract entirely in Behavioral Requirements, per the non-UI component guidance this recipe was
authored under.

