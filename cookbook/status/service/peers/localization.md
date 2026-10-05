
| String Key | Default (en) | Context |
|---|---|---|
| n/a — `DUPLICATE_PEER_MESSAGE` (exported constant, `base-url.ts`) | `A peer with that base URL already exists` | Hardcoded English, shared verbatim by the HTTP `/peers` route (a 409 body) and the `add_peer` MCP tool (both external to these three files) so both surfaces show the same sentence; neither this constant nor either external caller runs it through a localization/i18n layer. |
| n/a — `fetchPeers`'s caught-error `message` (`fetch.ts`) | e.g. `HTTP 502`, or the underlying error's own message | Persisted verbatim into `peer_snapshots.error`; whatever external surface displays it receives this exact English string with no localization. |

