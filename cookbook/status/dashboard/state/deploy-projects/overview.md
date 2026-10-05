
Deploy Projects is the status dashboard's client for the backend's deploy-projects enumeration: every deploy project (Vercel, Railway, Cloudflare Pages) seen in the deployments table, used when an operator browses projects to wire a monitored endpoint and when Auto Configure plans its wiring. The concept exposes:

- the data shapes `DeployProject`, `DeployProjectsResponse` and `UnconfiguredResponse`;
- two imperative read operations, the **deploy-projects read** (`GET /deploy-projects`) and the **unconfigured-partition read** (`GET /deploy-projects/unconfigured`), shared by the cached state, the Auto Configure run and the config-status badges so they "never drift on URL / flag / shape";
- a shared fresh-fetch latch and its arming operation;
- the cached state itself, which caches the snapshot under the cache key `["deploy-projects"]`.

All requests go through the injected status API client (see [status-web-api](adtoolkit://cookbook/status/dashboard/api)), so paths are relative to the host's API base.

