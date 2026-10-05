
- **Null build phase**: `combinedStatus` MUST return `"success"` for `{null, deployed}` and `"building"` for `{null, none}`. `isInFlight(null, "none")` MUST return `false`.
- **Null or undefined Vercel substate or target**: `readySubstate` and `target` MUST be treated as not `"PROMOTED"`, not `"ROLLING"` and not `"production"`, so `deployPhase` is `"none"`.
- **Empty strings**: An empty `readyState` or Railway `status` MUST map to `buildPhase` `"building"` and `deployPhase` `"none"`, the fallthrough branch.
- **Unrecognized provider values**: Any `readyState` or Railway `status` outside the listed literals, including a lowercase spelling, MUST map to `"building"`. That reads as in flight. The source bounds the claim elsewhere: `row-model.ts` demotes a `"building"` or `"queued"` `DeploymentDTO` whose `phaseConfirmedAt` outlives its confirmation window.
- **Strings outside the unions in `isInFlight`**: `isInFlight` MUST return `false` for any build or deploy string that is not an in-flight literal. Its parameters are typed `string`, not the unions.
- **Conflicting phases**: `combinedStatus` MUST resolve conflicts by fixed precedence: failed, then canceled, then unknown, then deployed, deploying, built, queued, and finally building. A `failed` on either lifecycle MUST beat an `unknown` on the other.
- **Canceled deploy phase**: `DeployPhase` has no `canceled` value, so only a canceled build yields `"canceled"`.
- **Railway failure attribution**: A Railway deploy-stage failure MUST read as `buildPhase` `"failed"`, because the source enum cannot separate the two.
- **Railway crash**: A `"CRASHED"` service MUST read as `"success"` through `combinedStatus`. Runtime health is left to other checks.
- **Drift from the server mirror**: If the server's in-flight phases or `combinedStatus` branches change, the web copy MUST change with them. `deploy-status-parity.test.ts` fails when they disagree. Nothing detects drift at compile time.
- **Concurrent access**: Not applicable. The module is stateless and runs on single-threaded JavaScript.
- **Error states and offline**: Not applicable. The module performs no I/O and receives already-fetched provider values.

