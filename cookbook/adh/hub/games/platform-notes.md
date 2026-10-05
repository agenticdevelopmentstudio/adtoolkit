
- **React/Web**: This is the reference implementation —
  `packages/web/packages/data/src/games/games.ts`. `gamesApi` and the
  `childApi(base, codec)` factory are plain `async` functions over
  `authedJson`/`authedRequest` (themselves over `fetch`); the two wire
  crossings are centralized in `gameFromWire`/`gameToWire`/
  `definitionFromWire`/`definitionToWire`, and `games.test.ts` (Vitest,
  with a stubbed global `fetch`) pins every route/body/crossing
  requirement documented above.
- **SwiftUI / AppKit / UIKit**: No Apple implementation of this domain
  exists yet. A port would model `Game`/`GameDefinition`/`GameEffect`/
  `GameMapping` as `Codable, Hashable, Sendable` structs (the closed-set
  fields as Swift `enum`s with a `String` raw value and a lenient
  `init(from:)` for an unrecognized wire value, mirroring the fallback
  behavior `narrow` gives the web client elsewhere in this package); the
  two wire crossings would live in each type's `Codable` `init(from:)`/
  `encode(to:)` rather than in free functions, and every network call
  would be an `async throws` `URLSession` request analogous to
  `EcosystemsDataSource`'s pattern in `hub-domain-ecosystems`.
- **Compose / Android**: A `data class` per row type (with a `sealed
  interface` or `enum class` for each closed set) plus `Retrofit`/`Ktor`
  service interfaces mirroring `gamesApi`/`childApi`'s four fixed base
  routes is the idiomatic equivalent; the two wire crossings would live in
  a `Moshi`/`kotlinx.serialization` custom adapter for the affected fields,
  and a `ViewModel` exposing `StateFlow` would replace the bare `Promise`
  return values.
- **WinUI 3**: `HttpClient` replaces `fetch`/`authedJson` for every
  `/api/game/*` request this recipe documents, with the Bearer token
  attached the same way `auth-client`'s access-token/refresh waterfall
  does today. `System.Text.Json` (`JsonSerializer`/`JsonNode`) replaces the
  `JSON.parse`/`JSON.stringify` pair in `jsonToText`/`textToJson` — a
  `JsonNode`'s `ToJsonString(new JsonSerializerOptions { WriteIndented =
  true })` reproduces the two-space indented text `jsonToText` produces,
  and `JsonNode.Parse` reproduces `textToJson`'s parse, with a caught
  `JsonException` translated into the same "<label> must be valid JSON."
  refusal. Each closed-set type (`GameCharacterNames`, `GameStatus`,
  `GameEventLog`, `GameDefinitionStatus`, `GameEffectTrigger`,
  `GameEffectOperation`) is naturally a C# `enum` with a
  `JsonStringEnumConverter`, though the web client's lenient behavior of
  falling back on an unrecognized backend string (via `narrow`, used
  elsewhere in this package) has no automatic .NET equivalent and would
  need an explicit converter that catches the enum-parse failure. A record
  type per row (`Game`, `GameDefinition`, `GameEffect`, `GameMapping`) with
  `Task`-returning methods on a small set of typed service classes — one
  per base route, or one generic class parameterized the way `childApi` is
  — reproduces the module's shape; `Uri.EscapeDataString` replaces `enc`
  for every id interpolated into a path.

