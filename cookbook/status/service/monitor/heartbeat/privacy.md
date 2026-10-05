
- **Data collected**: none of this file's own data. `url` is an opaque, potentially secret-bearing check-in endpoint (a healthchecks.io-style path) supplied by the caller; this file transmits no request body, no cookie, and no credential of any kind in the GET it issues — only the `User-Agent` header and whatever query/path segments are already baked into `url` itself.
- **Storage**: none. `pingHeartbeat` persists nothing to disk or a database; the module's only piece of state is the `HEARTBEAT_TIMEOUT_MS` constant.
- **Transmission**: exactly one outbound GET per call, to the caller-supplied `url`, with no body. Neither `console.error` message ever includes `url` itself — the non-2xx message names only the numeric status, and the failure message names only the caught error's text — so a check-in URL is never written to this file's own log output.
- **Retention**: not applicable — this file keeps no record of a ping after the call that made it resolves; there is no history or count of past pings anywhere in this module.

