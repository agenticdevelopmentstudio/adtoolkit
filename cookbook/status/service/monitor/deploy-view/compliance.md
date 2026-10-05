
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |

`unit-test-coverage` is `partial`: `deploy-env.test.ts` thoroughly exercises `envFromBranch` and `deployEnv`, including the Object.prototype boundary and every signal-precedence case, and exercises `isRealEnvDeployRow` indirectly through `providerDeployToDTO`'s `tier` assertions — but `isRealEnvDeploy`, `deployLinks`, and the `Indicator`/`IndicatorState` shapes have no dedicated test anywhere in this package. `separation-of-concerns` passes: the file's own header comment states its scope precisely (deploy/environment and link derivation only), explicitly disclaiming row construction (the web client's job) and problem derivation (the board's job); it reads no configuration and performs no I/O of its own. `explicit-error-handling` passes: every "no signal" case is propagated as an explicit `null` return (`envFromBranch`, and `isRealEnvDeployRow`'s DTO-level `tier` gate in `provider-deploy.ts`) rather than silently defaulting or throwing, and the one place a real exception could occur — URL parsing inside `projectPageUrl` — is caught there and turned into an explicit fallback value, not swallowed without a trace. `fault-tolerance` passes: the module accepts arbitrary caller-supplied strings (branch names, project names, URLs) including ones deliberately shaped to break a naive object-literal lookup, and every function returns a well-typed result rather than throwing for any input in its documented domain.

`unit-test-coverage`'s gap is the open question on `isRealEnvDeploy`/`deployLinks`/`Indicator`/`IndicatorState` — see the corresponding Design Decision above.

