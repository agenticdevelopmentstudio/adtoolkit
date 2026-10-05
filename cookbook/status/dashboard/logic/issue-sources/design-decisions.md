
**Decision**: Mirror the server's vocabulary by hand instead of sharing a module.
**Rationale**: Both files' doc comments name each other and promise "same union, same labels, same order". The client indexes `SOURCE_LABEL[row.source]`, so agreement is what keeps labels from rendering `undefined`. No shared package, generator or parity test exists, so agreement rests on editing both files together.
**Approved**: pending

**Decision**: Keep `glitchtip` as its own source rather than folding it into `http`.
**Rationale**: The doc comment says the other sources answer reachability while GlitchTip answers whether the site is throwing, and a site can be up on every probe with an error Problem open.
**Approved**: pending

**Decision**: Keep `STUCK_DEPLOY_MS` on the client even though no client code derives stuck Problems from it.
**Rationale**: The doc comment calls it a "mirror of the server threshold" and records the owner call of 2026-07-10 that an in-flight `building` row is activity, never a Problem. The constant stays as documentation of the backend's rule; the stuck verdict itself comes from the server.
**Approved**: pending

**Decision**: Add `isIssueSource` on the client only.
**Rationale**: Its doc comment says it lets a caller "filter/index by it without an unchecked `as IssueSource` cast". `row-model.ts` explains that `Row.source` is a plain string that can fall back to an activity `kind`, and the guard turns the fallback into a real branch.
**Approved**: pending

**Decision**: The platform-unreachable debounce stays out of this module.
**Rationale**: The closing note says the server's `applyPlatformIssues` and the `platform_health_state` table own the streak and threshold and publish a `platform-health|<source>` Problem, which the client renders as given.
**Approved**: pending

