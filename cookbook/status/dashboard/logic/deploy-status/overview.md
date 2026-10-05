
`deploy-status.ts` (`packages/web/packages/status-web/src/lib/deploy-status.ts`) is the status dashboard's copy of the platform-independent deploy vocabulary. It defines three string unions (`DeployStatus`, `BuildPhase`, `DeployPhase`), the `Phases` pair, the in-flight vocabulary (`IN_FLIGHT_BUILD_PHASES`, `IN_FLIGHT_DEPLOY_PHASE`, `isInFlight`), the in-flight `DeployStatus` values (`IN_FLIGHT_STATUSES`, `deployStatusInFlight`), two provider mappers (`vercelPhases`, `railwayPhases`) and the collapse function `combinedStatus`.

The module's own comment calls it "A HAND MIRROR of the server's deploy-status.ts (there is no shared build between the two packages)". The server original is specified in [Status Server Monitor Deploy Status](adtoolkit://cookbook/status/service/monitor/deploy-status). `deploy-status-parity.test.ts` imports both modules and asserts they agree across the full phase space.

Inside the web app, `types.ts` imports the three unions to type `DeploymentDTO.status`, `buildPhase` and `deployPhase`. `deploy-display.ts` imports `DeployStatus`. `row-model.ts` calls `deployStatusInFlight` in `deployDtoUnconfirmed` to decide whether a `DeploymentDTO` asserts live progress that may need demoting. The module has no state, no I/O and no side effects.

