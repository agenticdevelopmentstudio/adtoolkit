
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` (every operation) | string (caller parameter, optional) | omitted → caller's own owner scope | Percent-encoded and appended as `?workspace=<slug>` (or `&workspace=<slug>` on the list-endpoints operation); pins the operation to a workspace's owning principal instead of the caller's own scope. |
| body (create-group) | `{ name, slug, retentionDays? }` | none — required except `retentionDays` | Sent through the body-compaction helper as the `POST` body. |
| body (update-group) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `PUT` body. |
| body (create-site) | `{ name, slug, groupId }`, all required | none — required | Sent verbatim (renamed to `siteGroupId`) as the `POST` body; not passed through the body-compaction helper. |
| body (update-site) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper (renamed to `siteGroupId`) as the `PUT` body. |
| `siteId` (list-endpoints, create-endpoint) | string (caller parameter, required) | none | Identifies the parent site; sent as a query parameter on the list-endpoints operation and as a body field on the create-endpoint operation. |
| body (create-endpoint) | `{ url, kind, expectedStatus?, checkIntervalSeconds?, isActive? }` | none — `url`/`kind` required, rest optional | Sent through the body-compaction helper as the `POST` body, with `siteId` added from the operation's own parameter. |
| body (update-endpoint) | all fields optional | none — required argument, fields individually optional | Sent through the body-compaction helper as the `PUT` body; carries no `siteId` field. |
| valid endpoint kinds | fixed set (`"http"`, `"tcp"`, `"icmp"`) | fixed | The declared set of valid `kind` values; not consulted by the create-endpoint/update-endpoint operations (`endpoint-kind-passthrough`). |
| the three route paths | fixed path strings | fixed | `/api/monitoring/site-groups`, `/api/monitoring/sites`, `/api/monitoring/endpoints`; not injectable or configurable. |

