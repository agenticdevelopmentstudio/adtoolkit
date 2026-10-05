
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `app` | `OpenAPIHono<any>` | required | The Hono app instance whose `.openapi()`-registered routes seed the base document via `getOpenAPI31Document`; passed by the caller (`tools/dump-openapi.ts`, `test/openapi.test.ts`). |
| `version` | `string` | required | Embedded verbatim as `doc.info.version`; both current callers pass `config.appVersion`. |
| `MODULES` | internal constant (`build.ts`) | fixed, fourteen entries | Not a caller-supplied option — the list of hand-written `{ paths, schemas? }` modules is hardcoded in `build.ts` and changes only by editing the source file. |

