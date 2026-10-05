
- **Data collected**: this file transmits the caller-supplied Cloudflare API token as a Bearer credential on every request it makes; it reads back deployment ids, timestamps, and commit metadata (`commit_hash`, `commit_message`, `branch`) that Cloudflare itself already recorded from the account's own deploys. It collects no data from, and about, an end user of the monitored product.
- **Storage**: none in this file — it holds the token and every fetched row only in local variables and the returned `deploys` array for the duration of one call; persistence is entirely the caller's responsibility (`storage.deploy.upsertDeployments`, `sync.ts`, external).
- **Transmission**: the token is sent as `Authorization: Bearer <token>` on every request to `api.cloudflare.com`, over HTTPS (the URL is a hardcoded `https://` literal); no other destination ever receives the token. Cloudflare's own response, including commit metadata, is received over the same HTTPS connection.
- **Retention**: not applicable to this file directly — it retains nothing after the call returns; how long the mapped rows persist once upserted is governed by the caller's storage layer, external to this file.

