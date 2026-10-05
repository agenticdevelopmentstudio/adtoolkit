
Config Status is the single access point for configuration health in the status dashboard. It reads two independently cached queries and folds them into one `ConfigStatus<EndpointView, DeployProject>` model (the shape defined by the deploy-platform engine), so every "configured?" surface — the Overview banner, the Config page badges, the board rail — renders the same numbers from the same cache.

The two queries are deliberately separate:

- the **roster query** (cache key `["configure-data"]`, exported as `CONFIGURE_DATA_KEY`) — four local-database reads: groups, sites, integrations and all endpoints (`ConfigureData`).
- the **classification query** (cache key `["configure-classification"]`, exported as `CONFIGURE_CLASSIFICATION_KEY`) — the server's classified deploy-project partition from `GET /deploy-projects/unconfigured` (`UnconfiguredResponse`), which is a live scan of Vercel, Railway and Cloudflare.

A comment on the roster query records why the two are separate: the classification used to be a fifth leg of the same combined read, and "one flaky provider took the ENTIRE config editor down with it". Config Status also exposes `invalidateConfigQueries`, which invalidates both keys together.

