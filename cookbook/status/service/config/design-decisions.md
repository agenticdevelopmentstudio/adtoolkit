
- **Decision**: implement every `StatusConfig` field `envConfig` returns
  as a getter over the captured `env` reference, rather than snapshotting
  each value into a plain field at construction time.
  **Rationale**: the source's own doc comment states this directly — a
  host constructs one `StatusConfig` at module load, and a test that
  mutates `process.env` afterward (a common pattern in this test suite)
  still needs the config to see the new value; only a getter that reads
  `env` on each access can do that.
  **Approved**: pending
- **Decision**: strip at most one trailing slash from `publicBaseUrl`
  (`/\/$/`, not a global pattern), instead of normalizing away every
  trailing slash.
  **Rationale**: not stated in source; this is a plain fact about the
  code's actual behavior (see public-base-url-trailing-slash-strip), not
  an idealized rationale invented for this recipe. It differs from the
  fuller slash/case/port canonicalization `routes/config.ts` applies to a
  peer's `baseUrl` (external to these three files), which strips every
  trailing slash — the two call sites simply solve different problems.
  **Approved**: pending
- **Decision**: default `glitchtipProjects` to "every project the org
  returns" rather than "no project" when `GLITCHTIP_PROJECTS` is unset.
  **Rationale**: the source comment states this directly — a fleet with
  one GlitchTip project needs no configuration to work, and the allowlist
  exists for the second project to *require*, not for the first to wait on;
  an all-comma value (`",,"`) is treated as a mistake, not an instruction
  to silence the feature, for the same reason.
  **Approved**: pending
- **Decision**: leave `port` and `probeIntervalSeconds` as unvalidated
  `Number()` coercions while routing `deploySyncSeconds` and
  `github.fetchTimeoutMs` through the stricter `positiveNumber` helper —
  see the open question on numeric-env-validation.
  **Rationale**: not stated in source; the asymmetry is a plain fact about
  the code, not a defended design. It is flagged rather than resolved here
  because deciding whether to add validation, and where (this adapter vs.
  its HTTP-listen/probe-scheduler callers), is a call for whoever owns
  those callers, not something derivable from `env.ts`, `port.ts`, or
  `seed.ts` alone.
  **Approved**: pending
- **Decision**: gate the SEC-M5 production guard on `NODE_ENV` only, not on
  `RAILWAY_ENVIRONMENT_NAME` — see production-guard-environment-signal.
  **Rationale**: not stated in source. Recorded here rather than resolved
  because closing it requires knowing how this service's actual Railway
  deployment sets `NODE_ENV`, which is outside what these three files (or
  this recipe) can determine.
  **Approved**: pending
- **Decision**: this recipe carries roughly forty Behavioral Requirements
  against `status-server-auth`'s forty, despite `env.ts`/`port.ts`/`seed.ts`
  having far fewer conditional branches than the five auth files.
  **Rationale**: the count is comparable because most of this component's
  behavior is field-by-field derivation (one getter, one requirement) with
  only two real decision points (the SEC-M5 guard, `monitorLabel`'s
  qualification), not because the two components are equally complex; the
  per-field granularity keeps each requirement independently testable
  rather than bundling twenty getters into one compound statement.
  **Approved**: pending
- **Decision**: this recipe's `related` field links to
  `adtoolkit://cookbook/status/service/auth` one-directionally; the
  reverse link on `status-server-auth.md` was not added.
  **Rationale**: this recipe was authored under an explicit constraint to
  write only `cookbook/status/service/config.md` and touch no other file;
  cross-recipe-consistency's own text allows a unidirectional reference
  ("acceptable but bidirectional is preferred"), so this is a known,
  intentional gap in the preferred state, not an oversight.
  **Approved**: pending

**Decision**: The port and probe-interval getters do not validate their numeric environment values.
**Rationale**: It stands today because validation is left to the callers (the listen call and the probe scheduler). Closing it needs the teams owning those callers to decide whether the getters should apply the same positive-number guard, and a test for a non-numeric value.
**Approved**: pending

