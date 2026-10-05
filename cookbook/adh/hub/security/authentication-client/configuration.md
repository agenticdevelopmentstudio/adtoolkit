
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| API tokens collaborator | injected data source | none (required) | The root module's collaborator for personal API tokens; wrapped internally into the API tokens rail. |
| Storage tokens collaborator | injected data source | none (required) | The root module's collaborator for storage tokens; wrapped internally into the storage tokens rail. |
| API tokens rail's data source | injected data source | none (required) | Backs listing, fetching the scope catalogue, creating, and revoking personal API tokens. |
| Storage tokens rail's data source | injected data source | none (required) | Backs listing, creating, and revoking storage tokens, each call scoped by the given ecosystem. |
| Access lists topic's data source | injected data source | none (required) | Backs listing/fetching groups, create/update/delete, add/remove member, and upsert/remove grant. |
| Access lists topic's buckets collaborator | injected data source | none (required) | Supplies the bucket list/names and bucket-table list this topic renders alongside access lists; owned by the separate Buckets feature. |
| Ecosystem scope (storage tokens calls) | optional identifier | caller-supplied per call | Absent selects the caller's own (workspace) tokens; present selects that ecosystem's tokens. |
| Scope catalogue (create form) | list of strings, optional | caller-supplied per call | The scope catalogue for this create form; absent disables the save action entirely. |
| Row id length limit | integer literal `36` | fixed | Inline bound in the access lists topic's grant save action; not a named constant or injectable configuration. |
| Shared identifier pattern | string constants | fixed | Shared identifier rule (one lowercase letter or digit, optionally followed by lowercase letters, digits, or hyphens and ending in a letter or digit) plus its violation message, enforced on the storage tokens rail's `name` field. |

