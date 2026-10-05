
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `raw` (parameter to `toValidDate`) | `unknown` | none — caller-supplied | The provider- or webhook-supplied timestamp value to validate: an ISO string, an epoch number, or a `Date`. |
| `d`, `liveHost` (parameters to `providerDeployToDTO`) | `ProviderDeploy`, `string \| null` | none — caller-supplied | `d` is the in-memory deployment to shape; `liveHost` is the config-resolved live custom-domain host (external to this file, e.g. `ownerHostFor` in `routes/reads.ts`) stamped onto the result's `liveHost` field unchanged. |
| `id`, `d` (parameters to the module-private `isoOf`) | `string`, `Date` | none — caller-supplied only from within this file | `id` identifies the deploy in the logged error message when `d` is an Invalid Date; `isoOf` is not exported and has no caller outside `providerDeployToDTO`. |

