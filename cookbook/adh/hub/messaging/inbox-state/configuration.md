
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `DM_BASE` | module constant, `"/api/chat/dms"` | fixed | Not injectable; every DM request path is built as `${DM_BASE}/...`. |
| `PRESENCE_BASE` | module constant, `"/api/presence"` | fixed | Not injectable; the presence fetch's only base path. |
| `API_BASE` (notification logic) | module constant, `"/api/notifications"` | fixed | Not injectable; every notification request path is built from it. |
| `DM_PAGE_SIZE` | module constant, `100` | fixed | The initial DM conversation window and the increment the load-more action grows it by. |
| `DM_MAX_LIMIT` | module constant, `500` | fixed | The DM conversation window's hard ceiling; the load-more action clamps to it. |
| `chatId` (DM thread state) | `string \| null` (caller parameter) | none — required | The DM chat to load and stream; `null`/empty clears state and issues no request. |
| `recipientId` (start-DM action) | `string` (caller parameter) | none — required | The target user id; sent verbatim in the `POST` body. |
| query parameters (notification inbox state) | `status?`, `categories?`, `read?`, `page?`, `pageSize?` | `{}` | Serialized into the query string; an omitted field is left out of the query string entirely, not defaulted client-side. |
| `pollIntervalMs` (inherited from the shared live-connection transport) | number (ms) | `20 000` (shared transport default) | Neither the DM logic nor the notification logic passes its own value; both use the shared transport's fixed default. |

