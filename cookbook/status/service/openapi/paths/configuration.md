
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `app` | `OpenAPIHono<any>` (Hono) | Required, caller-supplied | The fully-mounted app instance `buildOpenApiSpec` reads `app.getOpenAPI31Document()` from, and (in `test/openapi.test.ts`) `app.routes` from; every route must already be registered before this call, since nothing here re-checks later. |
| `version` | `string` | Required, caller-supplied | Written into the assembled document's `info.version`; the tracked `openapi.json` normalizes this to `'0.0.0'` before comparison so a version bump alone never fails the drift guard's snapshot check. |
| `PERMANENTLY_UNDOCUMENTED` | `Set<string>` (`test/openapi-exclusions.ts`) | `GET /`, `GET /doc`, `GET /mcp`, `POST /mcp`, `DELETE /mcp` | The only allowed exceptions to "every registered route is documented"; adding an entry here is the one way to leave a route out of the OpenAPI surface without failing the test. |

