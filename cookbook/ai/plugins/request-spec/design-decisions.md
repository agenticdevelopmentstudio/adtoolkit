
**Decision**: `AIRequestSpec` validates none of its constructor arguments — an out-of-range `timeout`, a nonexistent `executableURL`, or an empty `headers`/`environment` dictionary are all accepted without complaint. (Apple platform implementation.)
**Rationale**: The type's entire job is to describe a request, not to judge one; validating `timeout` in particular would require this type to know how its one consumer (`withWallClockBudget`, called from `PluginTransport.run(spec:plugin:)`) interprets each boundary value (`NaN` → no budget, at/above roughly a year → no budget, at/below zero → immediate expiry — see `WallClockBudget.swift`'s documented policy), which is a decision that belongs to the consumer, not to the value it consumes.
**Approved**: pending

**Decision**: A `.command` transport's `environment` replaces the child process's entire environment when non-empty, rather than merging with the host process's own environment. (Apple platform implementation.)
**Rationale**: `PluginTransport.swift` states this explicitly (`environmentPolicy: .replace`) as matching prior `Process`-based behavior, and frames a plugin handing over a minimal environment as "isolating its child on purpose." A plugin that wants any host-inherited variable (most commonly `PATH`) available to its child, as `ClaudeLocalPlugin` does, MUST include it itself rather than relying on inheritance.
**Approved**: pending

**Decision**: `timeout` on an `.http`-transport instance simultaneously governs the request's overall wall-clock budget and `URLRequest`'s idle `timeoutInterval`. (Apple platform implementation.)
**Rationale**: `PluginTransport.runHTTP` passes `spec.timeout` to `URLRequest(url:timeoutInterval:)` in addition to wrapping the whole call in `withWallClockBudget(spec.timeout)`, even though the two express different guarantees — one bounds total elapsed time, the other resets on every received byte. `AIRequestSpec` exposes only one `timeout` field for both, so a value chosen to satisfy one semantics also applies to the other; there is no way, from this type alone, to give the two different bounds.
**Approved**: pending

**Decision**: `Method` declares a `.get` case, but no plugin under `packages/apple/AIPlugins/` currently constructs an `AIRequestSpec` with `method: .get`.
**Rationale**: Every current provider plugin (`ClaudeAPI`, `Google`, `OpenAI`, `OpenAICompatible`) issues its chat request as an HTTP POST with a JSON body, so `.get` is present for completeness and for a future or third-party plugin whose provider expects a GET request, not because any shipped code exercises it.
**Approved**: pending

