
- **Decision**: derive `providerProjectId`'s identity role as `providerProjectId ?? projectName` rather than requiring every platform to adopt a provider-issued project id before this field can be used at all.
  **Rationale**: stated directly in the field's own doc comment — keying identity on the coalesced value means a platform whose fetcher has not adopted ids keeps working unchanged, and adopting ids for a new platform is a per-platform change rather than a flag day across every consumer of `ProviderDeploy`.
  **Approved**: pending
- **Decision**: convert `providerProjectId` and `errorText` from an absent field to an explicit wire `null` in `providerDeployToDTO` (`?? null`) rather than passing an absent value straight through to the DTO.
  **Rationale**: stated directly in the mapper's own comment on `providerProjectId` — the DTO field is not optional the way the `ProviderDeploy` field is, so a consumer must be able to tell "this row genuinely has no id" from "this build of the DTO predates the field being added at all"; an absent key on the wire would conflate those two states.
  **Approved**: pending
- **Decision**: gate `tier` derivation on `isRealEnvDeployRow` before calling `deployEnv`, rather than letting `deployEnv` itself decide when to return a "no tier" answer.
  **Rationale**: stated directly in the mapper's own comment — `deployEnv` has no "don't know" to return, so a Vercel preview (no `environment`, a feature-branch `branch`, and a project name reused from the production project) would otherwise be badged with a tier by either of `deployEnv`'s own fallback signals; the gate has to be applied by the caller before asking `deployEnv` anything, and this is the same gate the board's `ownedDeployTarget` (external to this file) applies before a preview can become a Problem.
  **Approved**: pending
- **Decision**: give `isoOf` a fail-soft epoch fallback with a logged error, rather than letting an Invalid Date's `.toISOString()` throw a `RangeError` out of `providerDeployToDTO`.
  **Rationale**: stated directly in the source comment — a poisoned legacy row reaching this function unguarded would throw at serialize time and, per the test suite's own framing comment in `timestamp-validation.test.ts`, "500s /live for everyone"; substituting the epoch keeps one bad row from taking down every other row's response, at the cost of that one row displaying an obviously-wrong (epoch) timestamp instead. The source comment also notes new writes cannot produce this condition, because `toValidDate` gates every construction boundary — this fallback exists specifically for data written before that guarantee existed.
  **Approved**: pending
- **Decision**: model `confirmedAt` as an optional field with no default, rather than always requiring a caller to supply one (e.g. defaulting it to `createdAt` at construction time).
  **Rationale**: stated directly in the field's own doc comment — the many `ProviderDeploy` constructors that never observe a confirmation time distinct from creation (every current fetcher and webhook mapper) would otherwise each have to spell out the same fallback explicitly; leaving it optional and resolving the fallback once, centrally, in `providerDeployToDTO` (`d.confirmedAt ?? d.createdAt`) avoids repeating that rule at every construction site.
  **Approved**: pending

