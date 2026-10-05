
The Organizations domain is the hub's non-UI logic for organizations: it lists, resolves,
creates, renames, archives, and restores an *organization* — a workspace-owned record whose
creation provisions an ownership chain (a namespace, an admin team, and a default ecosystem) and
mints a reverse-domain identifier (rdid) — plus a companion operation for reading an organization
workspace's member roster. Six operations manage organizations, one operation reads the roster,
and a shared set of wire shapes describes the request and response bodies both read and send,
transcribed from the backend's own OpenAPI-documented component schemas.

This domain's own documentation frames its central fact: creating an organization is a
hand-written backend operation, *not* generic CRUD — it provisions state beyond the organization
record itself — and its authorization is split two ways that this recipe documents precisely:
creation is gated by the *workspace kind* the caller creates from (open in a personal workspace,
admin-of-the-org required from an org workspace), while renaming is gated by *which field* is
being changed (name/description need org-team-admin; a slug change needs site-admin, because it
re-mints the organization's global rdid tree). The list operation is deliberately workspace-scoped
rather than a pure membership listing, for the same reason the sibling Ecosystems domain's list is
workspace-scoped: an unscoped "the caller's organizations" list answered a membership question
that stayed identical no matter which workspace was open, silently misplacing an organization
inside the wrong workspace's own rail.

