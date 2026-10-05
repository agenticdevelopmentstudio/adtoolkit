
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| workspace slug (list, create) | string | none — required | Names the workspace whose organizations are listed, or the workspace an organization is created FROM (and will OWN). |
| key (resolve) | string | none — required | A UUID, slug, or reverse-domain rdid identifying the organization; passed through unmodified. |
| id (rename, archive, restore) | string | none — required | The organization's stored handle, percent-encoded into the URL path. |
| input (create) | create-organization input | none — required | `{ slug, name }`, sent verbatim as the `POST` body. |
| input (rename) | rename-organization input | none — required | Any subset of `{ name, slug, description }`; unset fields are omitted from the request body. |
| slug (roster list) | string | none — required | The organization workspace slug whose member roster is requested. |
| `/api/organization/organizations` | route literal, no exported constant | fixed | Base path every organizations operation inlines per call; unlike the sibling Ecosystems/Access clients, no shared base-route constant is extracted. |
| `/api/workspaces/<slug>/members` | route literal | fixed | Roster route the roster list operation inlines per call. |

