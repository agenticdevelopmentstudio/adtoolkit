
- **SwiftUI**: not applicable to these sources directly — this is a
  web-only component with no Apple counterpart given. A Swift port's
  networking/model layer (see AppKit/UIKit below) is the same regardless
  of whether the consuming UI is SwiftUI or AppKit; SwiftUI itself adds
  nothing beyond that shared layer.
- **AppKit / UIKit**: model `gamificationApi` as a small `struct`/`enum`
  namespace of `async throws` functions built on `URLSession`, mirroring
  each of the twelve methods 1:1; model the `wire.ts` interfaces as
  `Codable, Hashable` structs (mirroring the sibling
  `hub-domain-ecosystem-config` recipe's `sendable-models` convention)
  with a custom `CodingKeys`-free mapping since every wire field is
  already camelCase; represent `Seasons`'s `{...} | null` as `Seasons?`
  and `RealmConfigInput`'s per-field optionality as `Optional` properties
  encoded through a body builder that omits `nil` keys (mirroring
  `compact()` in `client-helpers.ts`) rather than emitting `null` for
  every absent field.
- **React / Web**: this is the source platform, and the only reference
  implementation given. `gamification.ts` (the twelve `gamificationApi`
  methods and their path builders — **realm-config-read**/
  **-partial-update-optionality**/**-update-always-returns-config**,
  **catalog-effective-merge**, **badge-create**/**-update-excludes-defaults**/
  **-delete-clears-holdings-first**, **levels-replace-wholesale**,
  **replay-scoping-via-body**, **event-types-list-name-ordered**/
  **event-type-create**/**-update**/**-delete**) and `wire.ts` (the wire
  types — `RealmConfig`, `RealmConfigInput`, `RealmConfigUpdate`,
  `RealmCatalog`, `CatalogBadge`, `CatalogLevel`, `RealmBadge`,
  `RealmBadgeInput`, `RealmLevelsInput`, `RealmLevelsUpdate`,
  `LevelRung`, `ReplayResult`, `RealmEventType`, `RealmEventTypeInput`,
  `Seasons`, `GamingMode`; marked "Type-only file" in its own header
  comment) live under `packages/web/packages/data/src/gamification/`.
  Every dynamic path segment is passed through `enc`
  (`encodeURIComponent`) before interpolation
  (**path-segment-encoding**); every write body is built with
  `JSON.stringify`, and `putRealmLevels`'s body is typed as an exact
  `{ rungs }` shape via the `satisfies` operator
  (**levels-replace-wholesale**). Every method issues its request
  through `authedJson` and never wraps it in a `try`/`catch`
  (**error-propagation-unmodified**, **no-response-caching**);
  `authedJson`/`authedFetch` (in `@agentic-toolkit/auth/client.ts`,
  outside these two given files) attach the bearer access token, convert
  a non-ok response to `AuthHttpError`, and perform the
  one-refresh-and-retry described in Edge Cases. `listEventTypes`
  performs no `.sort()` of its own — ordering is server-side
  (**event-types-list-name-ordered**). TypeScript's structural typing
  means none of `wire.ts`'s literal-union or numeric-range constraints
  (`tier`, `comparator`, `lengthDays` `1..366`, `≤64`-char fields) are
  checked at runtime by this module — only by the compiler at call sites
  and by the backend at request time.
- **Compose**: model each of the twelve operations as a `suspend fun` on
  a `GamificationApi` interface returning the Kotlin equivalent data
  class (`kotlinx.serialization.Serializable`); model
  `GamingMode`/`skin`/`tier`/`comparator` as `@Serializable` sealed
  classes or enums with an explicit `@SerialName` per value to match the
  exact wire strings; model `Seasons` as a nullable data class and
  `RealmConfigInput`'s per-field optionality with
  `@EncodeDefault(NEVER)`-annotated nullable properties so an absent
  field is omitted rather than serialized as `null`, matching
  `RealmConfigInput`'s partial-PUT contract.
- **WinUI 3**: model `gamificationApi` as a C# class whose twelve
  methods return `Task<T>` over `HttpClient`, using `System.Text.Json`
  with `JsonNamingPolicy.CamelCase` for the wire records; model
  `GamingMode`, `skin`, `tier`, and `comparator` as C# enums decorated
  with `JsonStringEnumConverter` so the serialized values match the
  TypeScript string literals exactly; model `Seasons` as a nullable
  record (`Seasons?`). The distinctive porting problem this recipe
  exists to flag: TypeScript's `field?: T` (omit-if-absent) versus
  `field: T | null` (explicit clear) distinction — used by
  `RealmConfigInput.seasons` to mean three different things (omitted,
  `null`, or an object) — has no direct C#/`System.Text.Json`
  equivalent, since a plain nullable property cannot distinguish "not
  provided" from "explicitly null." A WinUI 3 port needs either a
  wrapper type (e.g. an `Optional<T>` that tracks "was set") or a
  hand-built `JsonSerializerOptions`/`JsonConverter` pair that only
  emits a property when the C# caller explicitly assigned it, mirroring
  `compact()`'s undefined-key-dropping behavior in `client-helpers.ts`
  on the TypeScript side.

