
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` | data-source interface | none (required) | Injected transport for the user-auth topic: read and update operations. |
| `dataSource` | data-source interface | none (required) | Injected transport for the sign-in-apps topic: list / create / update / delete, all scoped by the ecosystem id. |
| `dataSource` | data-source interface | none (required) | Injected transport for the feature-flags topic: list / create / update(key) / delete(key). |
| `dataSource` | data-source interface | none (required) | Injected transport for the server-bags topic: list / create / update(key) / delete(key). |
| `dataSource` | data-source interface | none (required) | Injected transport for the storage-tokens topic and its shared rail: list / create / revoke, where an absent ecosystem id means the caller's own workspace tokens. |
| `ecosystem` | record | none (required) | Supplies the id/slug used to scope every list/create/update/delete call and to build composite detail ids. |
| `path` | list of navigation-path segments | empty | Rail-relative navigation path; see **path-depth-dispatch**. |
| `rail` | rail-provider interface | none (required, unused) | Passed to every rail path resolution per the topic-provider contract; none of these five topics call back through it themselves. |
| ecosystem id (alternate client) | string | none (required) | Ecosystem id, percent-encoded into every ecosystem-config request path. |
| scope parameters (alternate client) | optional strings | unset | Optional query-string scoping used only by the token operations. |

