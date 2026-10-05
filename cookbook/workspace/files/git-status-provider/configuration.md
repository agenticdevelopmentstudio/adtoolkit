
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repoRoot` (construction parameter) | a file-system location | none — required | The checkout this provider reports on; fixed for the instance's lifetime. |
| `client` (construction parameter) | the git-client abstraction | the shared instance | Injectable git client; a test substitutes a differently-configured or fake instance. |

Neither this component nor its companion color mapping reads an environment
variable or a settings key directly. The git executable path, timeout, and
submodule handling are configuration concerns reached only indirectly,
through whichever client is injected.

