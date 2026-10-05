
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `DEPLOYMENT_ENV` (server-only environment variable) | `string \| undefined` | none — MUST be set by the deploy pipeline | Read by the server-side membership check; carries no build-time-inlined prefix, so it never reaches the browser. |
| `NEXT_PUBLIC_DEPLOYMENT_ENV` (build-time-inlined environment variable) | `string \| undefined` | `undefined`, which folds the build-time flag to `false` | Read once at module load to compute the build-time flag; promoted from the server-side `DEPLOYMENT_ENV` value by the project's shared build-configuration helper so one deploy-time value produces both reads. |
| input to the server-side membership check | `string \| null \| undefined` | caller-supplied, no default | The value tested against the allowlist; production callers pass the current value of `DEPLOYMENT_ENV`. |

