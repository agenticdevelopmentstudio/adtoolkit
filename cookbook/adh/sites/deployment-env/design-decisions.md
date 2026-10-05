
- **Decision**: Duplicate the "is this a dev env" fact as two separate
  declarations — `isDevDeploymentEnv` reading `DEPLOYMENT_ENV`, and
  `DEV_BUILD` reading `NEXT_PUBLIC_DEPLOYMENT_ENV` via three literal `===`
  comparisons — rather than deriving one from the other.
  **Rationale**: per the source's own comment, they answer different
  questions for different audiences (what a server RENDERS vs. what a dev
  BUILD DOES), and `DEV_BUILD` additionally has to stay in a form the
  bundler's constant folder can reduce to a literal, which
  `DEV_DEPLOYMENT_ENVS.includes(...)` would defeat; the duplication is
  therefore load-bearing, not an oversight, and it is pinned by
  `deploymentEnv.test.ts`'s "stays written as constant-foldable literal
  comparisons" test.
  **Approved**: pending
- **Decision**: Reserve `DEV_BUILD`/`isDevDeploymentEnv` for what gets
  rendered or what a dev build does, and require any consumer that gates a
  dynamic `import()` on the dev/production distinction to follow a separate
  four-leg chunk-gate contract (inline literal comparisons at the import
  site, a package-subpath specifier, a matching bundler entry plus
  `external`, and a package.json export) instead of importing `DEV_BUILD` at
  that site.
  **Rationale**: the source's own top-of-file comment states this is why an
  earlier `DEV_BUILD ? dynamic(() => import('./X'))` shipped the whole
  site-theme editor, Monaco included, into every production build of every
  site — a bundler's dead-code elimination for a dynamic import resolves
  only a literal comparison visible while parsing that exact call site, and
  does not follow an imported identifier back to its definition.
  **Approved**: pending
- **Decision**: Place this module in `@agentic-toolkit/adh-registry` rather
  than in `@agentic-toolkit/adh`, where most of its consumers live.
  **Rationale**: `adh` depends on `adh-registry`, so a home in `adh-registry`
  is readable from both sides of that dependency edge — including
  `adh-registry`'s own `seo/metadata.ts`, which needs the same fact — while a
  home inside `adh` could not be read from `seo/metadata.ts` without
  introducing a dependency cycle.
  **Approved**: pending
- **Decision**: Guard the cross-repo copy of this allowlist
  (`adhbackend`'s `isThemeSurfaceEnv`) by having
  `adhbackend/src/adh/test/themeSurfaceEnv.test.ts` regex-extract
  `DEV_DEPLOYMENT_ENVS`'s literal array text out of this file's source text,
  rather than importing the module.
  **Rationale**: `adhbackend` is a standalone pnpm package that must not take
  a build dependency on the frontend package this file lives in; reading the
  source text instead lets the two lists be checked for drift in both
  directions without creating that dependency, at the cost of coupling the
  check to this file staying at its current path and keeping the array
  written as a literal the regex can match — the test's own comment states
  it "fails loudly if that file moves."
  **Approved**: pending
- **Decision**: Allowlist the three dev environments explicitly
  (`=== 'local' || === 'testing' || === 'staging'`) rather than testing the
  inverse (`!== 'production'`), in both `isDevDeploymentEnv` and
  `DEV_BUILD`.
  **Rationale**: per the source comment, this makes an unset or misspelled
  environment fail SAFE (dev tooling hidden) instead of failing OPEN (dev
  tooling exposed to real visitors) — the asymmetry matters because a
  wrongly-"dev" gate does not crash and is not noticed by CI, it just ships
  extra code and behavior to production silently.
  **Approved**: pending

