
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `targetKind` | `string` | none (required) | The subject's kind (e.g. `"project.comments"`); passed to `list` and `add`, URL-encoded via `enc()` for `list`'s query string and sent verbatim in `add`'s JSON body. |
| `targetIds` | `string[]` | none (required) | Subject ids to batch-read via `list`; de-duplicated, filtered of falsy entries, and chunked at `MAX_TARGET_IDS`. |
| `targetId` | `string` | none (required) | The single subject id passed to `add`, sent verbatim in the JSON body (not URL-encoded, since it travels in the body, not the path). |
| `emoji` | `string` | none (required) | The reaction glyph passed to `add`; no client-side format or length check. |
| `reactionId` | `string` | none (required) | The reaction's own id passed to `remove`, URL-encoded via `enc()` into the DELETE path. |
| `viewerId` | `string \| null` | none (required parameter of `tally`) | The reader's own user id (typically from `readTokenSubject()`, outside these given sources); `null`/`""` makes every `ReactionTally.mine` read as not-mine. |
| `MAX_TARGET_IDS` | `number` (module constant) | `200` | The backend's cap on one batched `list` read; fixed in `reactions.ts`, not caller-configurable — changing it requires editing the source. |
| Bearer access token | implicit environment dependency | none | Attached to every request by `authedJson`/`authedRequest`/`authedFetch` (in `@agentic-toolkit/auth/client.ts`, outside these two given files) via `readAccessToken()`; not a parameter of any `reactionsApi` method. |
| Request base path | implicit environment dependency | `/api/content/reactions` (relative) | Every path is relative, resolved against the current page origin through the host's `/api/:path*` BFF proxy; no base-URL environment variable appears in `reactions.ts`. |

