
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dataSource` | the applications data source | none (required) | Backs the list/get/create/update/delete/rename-identifier/schema-grants/set-schema-grants/tokens/create-token/revoke-token operations. |
| `buckets` | the buckets data source | none (required) | Supplies the ecosystem's bucket list and bucket-table list this topic uses to label and enumerate schema/table grants; owned by the separate Buckets feature. |
| Consumer kind values | enumerated string | decode fallback "developer" | The three consumer kinds (staff, developer, customer) a caller can assign to an application. |
| Slug format rule | string pattern + message | fixed | Shared identifier rule enforced on both the create form's and the settings form's `slug` field. |
| Default grant permissions | CRUD-permissions value | `"R"` (read-only) | Starting permission set for a schema grant created by the "Add schema" save action. |

