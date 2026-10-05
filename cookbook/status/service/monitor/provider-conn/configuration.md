
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` (parameter) | `Storage` | required, caller-supplied | `providerConn` reads `storage.config.listIntegrations()`; `enumerateDeployProjects` additionally reads `storage.deploy.listProjectMeta()`. |
| `config` (parameter) | `StatusConfig` | required, caller-supplied | Only `config.secrets` is read, by the `tokenEnvVar` name each active integration row supplies; `config.credentials` is never read by this file. |
| Integration row `tokenEnvVar` | `string \| null` (`IntegrationRow`) | `null` — that provider's token stays `undefined` | The credential NAME `providerConn` looks up in `config.secrets`; never a literal token value itself. |
| Integration row `isActive` | `boolean` (`IntegrationRow`) | — | Only rows with `isActive === true` are passed into `providerConnFromIntegrations`; inactive rows are filtered out before this module hands anything to `deploy-platform`. |
| Integration row `config` | `Record<string, unknown>` (`IntegrationRow`) | `{}` | Non-secret per-provider settings (`teamId`, `accountId`, `workerScripts`, `projects`) `providerConnFromIntegrations` reads, keyed by provider platform name. |

