
Not applicable: this file defines no application URL scheme or route of its own — it only issues outbound `fetch` calls to Vercel's REST API (`/v9/projects`, `/v9/projects/<name>/domains`, `/v6/deployments`, `/v2/teams[/<id>]`) and returns in-memory `VercelProdState`, `VercelProjectMeta`, and `ProviderDeploy` rows; the `sourceUrl` strings it composes are `https://vercel.com/...` dashboard links consumed by the caller, not this file's own routes.

