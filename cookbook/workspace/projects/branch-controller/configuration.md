
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| checkout (construction parameter) | the checkout | none — required | The checkout this component owns; fixed for the instance's lifetime, though the checkout it names may switch branches without a new component being built. |
| git client (construction parameter) | the git client | none — required, no internal fallback | Injected by the caller; branch management never falls back to a shared default itself. |
| git status provider (construction parameter) | the git status provider | none — required, no internal fallback | Injected by the caller via the project workspace's per-directory status-provider lookup, so every consumer of one checkout's status shares one provider. |

This component reads no environment variable and no settings key directly;
git executable path, timeout, and submodule handling are git client
configuration concerns reached only indirectly through the injected git
client.

