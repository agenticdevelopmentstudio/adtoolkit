
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `platform` (parameter to `deployEnv`, `isRealEnvDeployRow`, and via `d.platform` to `isRealEnvDeploy`) | `string` | none — caller-supplied | The deploy's platform identifier (`"vercel"`, `"railway"`, `"cloudflare-pages"`, `"crunchy"`, ...); only the literal value `"vercel"` changes this file's branching behavior. |
| `projectName` (parameter to `deployEnv`) | `string` | none — caller-supplied | Passed straight through to `envFromProject` on every fallback path this file reaches. |
| `storedEnv` (parameter to `deployEnv`) | `string \| null` | none — caller-supplied | The provider's own reported environment/promotion target; consulted only on the non-Vercel fallback path (deploy-env-nonvercel-fallback). |
| `branch` (parameter to `deployEnv` and `envFromBranch`) | `string \| null` | none — required, no default (deploy-env-branch-required-param) | The deploy's source-control branch; the highest-precedence of the three signals `deployEnv` considers. |
| `url` (parameter to `deployLinks`) | `string \| null` | none — caller-supplied | The provider's raw deploy/inspector URL, reshaped into `sourceUrl` via `projectPageUrl`. |
| `liveHost` (parameter to `deployLinks`) | `string \| null` | none — caller-supplied | A bare hostname (no scheme), per `DeploymentDTO.liveHost`'s own field comment ("resolved live custom domain host"); `deployLinks` prefixes it with `https://` and performs no further validation of its shape. |
| `BRANCH_ENV` (module-level constant) | `ReadonlyMap<string, string>` | fixed 3 entries: `"prepared"` → `"testing"`, `"staging"` → `"staging"`, `"production"` → `"production"` | Not configurable at runtime; adding, removing, or overriding an entry requires editing this file. This file reads no environment variable and consults no injected configuration object of its own. |

