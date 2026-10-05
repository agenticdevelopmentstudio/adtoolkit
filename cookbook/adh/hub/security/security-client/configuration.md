
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Tokens base path | fixed string constant, `"/api/auth/tokens"` | fixed | Not injectable; every token request path is built from this base. |
| Groups base path | fixed string constant, `"/api/bucket/access-groups"` | fixed | Not injectable; the base path for group/member/grant operations by group id. |
| Buckets base path | fixed string constant, `"/api/bucket/buckets"` | fixed | Not injectable; used only by group-create's `{bucketsBase}/{bucketId}/access-groups` path. |
| Mint body | `{ name, expiresAt?, scope? }` | none — required | Sent verbatim as the request body; `expiresAt`/`scope` are omitted from the wire body entirely when left absent. |
| Token id (revoke) | string (caller parameter) | none — required | The token's id; percent-encoded before being placed in the URL. |
| Bucket id (group-create) | string (caller parameter) | none — required | The owning bucket; percent-encoded. |
| Group id (most bucket access-list operations) | string (caller parameter) | none — required | The access group's id; percent-encoded. |
| Group-create input | `{ name: string; description?: string }` | none — required | `name` is trimmed before send; `description` is sent only when truthy. |
| Group-update patch | `{ name?: string; description?: string }` | none — required | Each key is sent only when the caller supplies it (checked for presence, not truthiness). |
| Add-member input | `{ memberType; memberId: string }` | none — required | Sent verbatim as the request body. |
| Member-row id (remove-member) | string (caller parameter) | none — required | The membership row's own id, not the principal's id. |
| Upsert-grant input | `{ targetType; targetId: string; crud: string }` | none — required | Sent verbatim as the request body; `crud` is not validated client-side. |
| Grant id (delete-grant) | string (caller parameter) | none — required | The grant's id; percent-encoded. |

