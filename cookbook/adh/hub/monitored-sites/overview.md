
This is the client for the Status Sites monitoring domain: groups, sites, and endpoints, backed by
generic CRUD over `/api/monitoring/site-groups`, `/api/monitoring/sites`, and
`/api/monitoring/endpoints`. The model matches the database, not an earlier prototype: a site
belongs to exactly one group (`sites.site_group_id`, `NOT NULL`, FK `ON DELETE CASCADE`) and an
endpoint belongs to exactly one site (same cascade) — a strict 1:M chain, not the prototype's
many-to-many `groupIds[]`. The whole chain is owner-scoped server-side, with an optional
`workspace` parameter on every operation that re-pins it to a workspace's owning principal. This
logic holds the backend row and request-body shapes (a group row, a site row, an endpoint row, and
their create/put bodies), three mappers from row to caller-facing view, the caller-facing create
and update body shapes for each entity, the fixed set of valid endpoint kinds, and twelve
operations — list/create/update/delete for each of the three entities — each a thin request
builder over a shared authenticated request client. It is a headless **logic** module — no visual
surface — consumed today by the Dashboards (Site Monitoring) feature, so this recipe marks
Appearance, States, and Accessibility not applicable and carries the runtime contract entirely in
Behavioral Requirements, per the non-UI component guidance this recipe was authored under.

