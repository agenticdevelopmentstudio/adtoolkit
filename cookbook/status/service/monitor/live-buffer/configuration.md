
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `deploy` (parameter to `pushDeployEvent`) | `ProviderDeploy` | none — required on every call | The deploy event to buffer, already mapped from a webhook payload and typed by the caller (`hooks.ts`'s `mapVercelDeployEvent`/`mapRailwayDeployEvent`); this module performs no validation of its shape. |
| `sinceMs` (parameter to `deployEventsSince`) | `number` | none — required on every call | The inclusive lower bound, in milliseconds, on `receivedAt`. The module's one production caller (`reads.ts`'s `deploymentDtos`) always passes `0`, so in the shipped system every buffered entry is returned on every read (see Design Decisions). |
| `CAP` (module constant) | `number` | `200` | The ring buffer's maximum length. Not caller- or environment-configurable — it is a hardcoded, unexported module constant with no override parameter of any kind. |

