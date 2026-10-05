
This is the status backend's OpenAPI documentation layer: fourteen modules under
`src/openapi/paths/` (`activity`, `auth`, `autoConfigure`, `badge`, `board`,
`config`, `device`, `fleet`, `hooks`, `reads`, `stream`, `telemetry`, `tokens`,
`users`), each documenting one plain-Hono route file's operations as OpenAPI 3.1
path items and, where it introduces a reusable shape, named component schemas.
`shared.ts` supplies the vocabulary every module builds with (`BEARER`, `jsonBody`,
`ref`, `errors`, `okJson`, `okFlag`, `pathParam`, `queryParam`, `zodJson`), and
`route-key.ts`'s `normHonoPath` normalizes a Hono route pattern into the same path
key form these modules use. `build.ts`'s `buildOpenApiSpec` merges the fourteen
modules' `Paths`/`Schemas` exports with the app's five natively `.openapi()`-
registered routes (`/health`, `/version`, `/public/status-summary`, the merged
`/cron/*` pair) into the document served at `GET /doc`. `test/openapi.test.ts` is
this component's drift guard: it fails the build the moment a route `createApp()`
registers goes undocumented (unless listed in `test/openapi-exclusions.ts`'s
`PERMANENTLY_UNDOCUMENTED`), the moment a documented path stops matching a real
route, or the moment the committed `openapi.json` (written by `pnpm openapi:dump` /
`tools/dump-openapi.ts`) drifts from a fresh build. This recipe treats the fourteen
modules, `shared.ts`, and `route-key.ts` as one component: the contract that keeps
the status backend's served API documentation honest about its actual routes.

