
This is the client for the gated workspace roles & permissions access surface: feature
areas, role CRUD, subject assignments, item restriction, and an effective-access explainer.
Every operation names the workspace by slug (a personal workspace's customer slug or an org
slug); reads answer with a not-found response to non-members, role definition is admin-only,
and assignment/restriction writes need the manage-access verb at the target scope, all
enforced by the backend. The client exposes a set of wire row shapes (for feature areas,
grants, roles, assignments, and effective-access results), a fallback feature-areas list,
write input shapes for role and assignment writes, and ten operations, each a thin request
builder over a shared authenticated-request helper. It is a headless **logic** module — no
visual surface — so this recipe marks Appearance, States, and Accessibility not applicable
and carries the runtime contract entirely in Behavioral Requirements, per the non-UI
component guidance this recipe was authored under.

