
- **Empty endpoints array**: When `siteLinks()` receives an empty endpoints array, `live` MUST be `null` (no endpoint to select). The `platform` field MUST still be computed correctly.
- **Undefined environment property**: When an endpoint object in the array lacks an `environment` property, it MUST be treated as a non-production endpoint and available as a fallback only if no production endpoint exists.
- **Empty url string**: `url` is typed as a required `string`; an endpoint whose `url` is `""` produces `live: "https://"` because `liveUrl` prepends the scheme without checking for an empty host.
- **Null platform parameter**: When `siteLinks()` is called with `site.platform === null` or `undefined`, `platformDashboardUrl()` MUST canonicalize it and return `null` (no recognized platform).
- **Empty projectName**: When `platformDashboardUrl()` receives an empty string as projectName, it MUST return `null` (falsy check applies).
- **URL scheme detection case-insensitive**: The scheme pattern in `liveUrl()` uses the `i` flag; `HTTP://` and `Https://` MUST be recognized as having a scheme.
- **Project name with special characters**: When a projectName contains characters requiring URL encoding (spaces, slashes, ampersands), `encodeURIComponent()` MUST encode them in the Vercel and Cloudflare dashboard paths; the Railway path does not include the project name.

