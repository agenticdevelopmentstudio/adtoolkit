
Four independent roles, plus one sibling role, form the client-side contract for everything the Hub's
"Authentication" surface manages: a **root module** is the hierarchical-detail root — "Tokens" — that
routes to two child rails and an explainer; an **API tokens rail** mints, lists, reveals-once, and
revokes the caller's personal API tokens (`tmp_…`, scoped by REST path); a **storage tokens rail**
(shared with a separate ecosystem-configuration feature) does the same for storage tokens (`adh_…`,
each its own principal with one isolated bucket), parameterized by an optional ecosystem id so the
identical rail serves both the caller's own tokens (no ecosystem given) and a specific ecosystem's
tokens; and an **access lists topic** is a separate topic provider — the "Access" product-rail topic —
managing bucket access-control lists (groups), their members, and their create/read/update/delete
grants, nested three levels deep. A shared models file holds the wire types and the four data-source
contracts (for API tokens, bucket access, and storage tokens) that all four roles depend on but never
implement themselves — every network call is delegated to an injected data source, and every thrown
error is normalized to a single named error type before it reaches a caller. The access lists topic is
not reachable from the root module's tree — the two share vocabulary (the named error type, a shared
form specification shape, reveal-once secrets) but are wired into the app as two independent entry
points.

