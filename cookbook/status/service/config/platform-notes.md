
- **React/Web** (source platform): the three files live under
  `packages/web/packages/status-server/src/config/`, barreled through
  `index.ts`. `env.ts` reads a plain `Readonly<Record<string, string | undefined>>`
  (`EnvSource`) rather than importing `process` directly, so it also runs
  against a test fixture object; `port.ts` and `seed.ts` import nothing
  outside this package. The monitor-worker boundary these files are shaped
  for (`workerData`/`structuredClone`) is Node's `worker_threads`, in
  `src/monitor/worker-client.ts` and `worker.ts`, external to this recipe's
  three files.
- **SwiftUI / AppKit / UIKit**: no UI surface to port. A Swift
  re-implementation of this CONFIG PORT for a companion backend (Vapor or
  Hummingbird) would model `EnvSource` as `[String: String]` read from
  `ProcessInfo.processInfo.environment`, `StatusConfig` as a `Sendable`
  `struct` whose fields are plain stored properties resolved once at
  construction — Swift has no cheap analogue to a JS getter closing over a
  captured dictionary, so lazy-field-evaluation's "read at access, not at
  build" behavior would need to be reproduced explicitly (e.g. a computed
  property reading a stored `[String: String]`) if that semantics is
  required. `STATUS_CREDENTIAL_NAMES` maps to a `static let` array of an
  enum with a `String` raw value.
- **Compose**: same non-UI relationship. A Kotlin backend (Ktor) would model
  `EnvSource` as `Map<String, String?>` from `System.getenv()`, and
  `StatusConfig` as a `data class` whose numeric fields use `String?.toIntOrNull()`
  / `toDoubleOrNull()` — which, unlike the source's bare `Number()`, already
  returns `null` on a malformed string, closing the numeric-env-validation
  gap for free in a Kotlin port.
- **WinUI 3**: a WinUI 3 desktop app is a client of this backend and does
  not reimplement this config port; if a future product needed a .NET
  companion backend (ASP.NET Core Minimal API) that DID reimplement it, the
  mapping is concrete: `EnvSource` becomes an `IConfiguration`
  (`Microsoft.Extensions.Configuration`, or plain
  `Environment.GetEnvironmentVariable`); `StatusConfig` becomes an immutable
  `record` whose numeric properties are expression-bodied
  (`public int Port => int.TryParse(Env("PORT"), out var p) ? p : 3000;`),
  which both preserves the source's per-access laziness AND gets
  `int.TryParse`/`double.TryParse`'s built-in validation for free — the
  exact gap flagged by numeric-env-validation does not reproduce in a
  faithful C# port unless someone deliberately drops the `TryParse` guard.
  `STATUS_CREDENTIAL_NAMES` becomes a `static readonly ImmutableArray<string>`;
  `SeedEnvironment` becomes an `enum { Production, Staging, Testing }`;
  `SeedRoster` becomes `IReadOnlyList<SeedEndpoint>` of an immutable
  `record SeedEndpoint(string Group, string Name, string BaseSlug, string Host, IReadOnlyList<SeedEnvironment> Envs, string Kind, string? Path = null, int? ExpectedStatus = null)`.
  Because a `StatusConfig` here would likewise need to cross a background
  `Task`/`AppService` boundary, it should stay `System.Text.Json`-serializable
  with no delegate members — the same "no method survives the boundary"
  constraint the source states for `structuredClone`.

