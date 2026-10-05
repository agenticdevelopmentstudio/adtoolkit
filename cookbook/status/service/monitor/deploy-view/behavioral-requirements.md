
### Data Shapes

- **indicator-shape**: An `Indicator` value MUST carry exactly two fields — `state: IndicatorState`, where `IndicatorState` is the three-member union `"ok" | "warn" | "down"`, and `count: number` — and a literal using another `state` value or omitting either field MUST fail to type-check.
- **env-from-project-reexport**: This module MUST re-export the `envFromProject` function it imports from `@agentic-toolkit/deploy-platform/canon` unchanged, so a caller importing `envFromProject` from `./deploy-view` gets the identical function, and identical results, as a caller importing it directly from the `canon` package.

### Environment Derivation

- **branch-env-lookup**: `envFromBranch` MUST return `"testing"` for branch `"prepared"`, `"staging"` for branch `"staging"`, and `"production"` for branch `"production"`, and MUST return `null` for any branch string not one of those three, including one that names a property inherited from `Object.prototype` (for example `"constructor"`, `"toString"`, `"valueOf"`, `"hasOwnProperty"`, `"__proto__"`).
- **branch-env-nullish-input**: `envFromBranch` MUST return `null` when its `branch` argument is `null`, `undefined`, or the empty string, without consulting the lookup table.
- **branch-env-main-excluded**: `envFromBranch` MUST return `null` for branch `"main"` specifically; `"main"` MUST NOT appear as a key in the branch-to-tier lookup, per the source's own comment that `main` deploys nothing and therefore carries no evidence about any tier.
- **deploy-env-branch-precedence**: `deployEnv` MUST return whatever `envFromBranch(branch)` returns whenever that call returns a non-null value, regardless of what `platform`, `projectName`, or `storedEnv` are — including when the project-name or stored-environment signal would otherwise disagree with the branch.
- **deploy-env-vercel-fallback**: When `envFromBranch(branch)` returns `null` and `platform === "vercel"`, `deployEnv` MUST return `envFromProject(projectName)`, ignoring `storedEnv` entirely.
- **deploy-env-nonvercel-fallback**: When `envFromBranch(branch)` returns `null` and `platform !== "vercel"`, `deployEnv` MUST return `storedEnv` unchanged when it is a non-empty string, and MUST return `envFromProject(projectName)` when `storedEnv` is `null` or the empty string.
- **deploy-env-branch-required-param**: `deployEnv`'s `branch` parameter MUST have no default value; a caller with no branch to offer MUST pass `null` explicitly rather than omitting the argument.

### Real-Deploy Classification

- **is-real-env-deploy-row**: `isRealEnvDeployRow` MUST return `false` only when `platform === "vercel"` and `environment` is `null` or the empty string, and MUST return `true` for every other combination of `platform` and `environment`, including a non-Vercel platform whose `environment` is `null` or empty.
- **is-real-env-deploy-delegates**: `isRealEnvDeploy` MUST return exactly the value `isRealEnvDeployRow(d.platform, d.environment)` would return for the given `DeploymentDTO d`, reading only its `platform` and `environment` fields.

### Links

- **deploy-links-source-url**: `deployLinks` MUST set the `sourceUrl` field of its result to `projectPageUrl(url)` (from `./url.ts`): for a Vercel inspector URL (hostname `vercel.com` with at least three path segments), the result collapses to `<origin>/<team>/<project>`; for any other URL, for a URL that fails to parse, or when `url` is `null`, the result passes through unchanged.
- **deploy-links-live-url**: `deployLinks` MUST set the `liveUrl` field of its result to `` `https://${liveHost}` `` when `liveHost` is a non-empty string, and to `null` when `liveHost` is `null`, and MUST NOT derive `liveUrl` from `url` or from the computed `sourceUrl` in either case.

### Ordering and Concurrency

- **module-state-immutable**: `BRANCH_ENV` MUST be constructed once, as a read-only `Map`, when the module is loaded, and no exported function in this file MUST mutate it; every derivation in this file MUST be a pure function of the arguments passed to it, with no other module-level mutable state. Because nothing here performs an `await` and JavaScript executes one module instance's code on a single thread, concurrent calls into these functions from the same thread MUST NOT interleave in a way that corrupts a result — this is a structural fact of the runtime and the file's own statelessness, not a lock this file implements.

