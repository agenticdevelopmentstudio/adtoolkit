
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `topics` | ordered list of topic providers | none — required | The ordered set of topics a product's rail exposes; the root listing imposes no fixed order or fixed membership |
| `parent` | an ecosystem, optional | none | When set, the new ecosystem is created as a child of this ecosystem; when absent, the prefix comes from resolving the caller's infrastructure id |
| slug length ceiling | integer constant | `64` | Client-side slug length ceiling enforced before any network call |
| `workspaceSlug` | string, optional | none | Selects the workspace principal's infrastructure row; omitted resolves the caller's own |
| `parent` / `workspace` scoping options | strings, optional | both absent | Scope a create to a parent ecosystem or a workspace's principal; `parent` wins if both are given |
| ecosystems base route | internal constant | fixed | Base route for every generic create/read/update/delete ecosystems call |
| identifiers base route | internal constant | fixed | Base route for rdid rename/availability |
| features base route | internal constant | fixed | Base route for the feature catalog, provisioned list, add and remove |
| `ecosystemId` | string, optional | none — required | The ecosystem (rdid or opaque id) whose features are listed or changed; the list query is disabled while it is falsy |
| `keys` | list of strings | none — required | Catalog keys to add in one batch |
| feature change `{ add, remove }` | lists of strings each | none — required | One picker visit: keys to add (one add request), provisioned keys to remove (one removal request each) |
| catalog freshness window | internal constant | `30 * 60 * 1000` ms | How long the session-wide catalog is served from cache before a refetch |

