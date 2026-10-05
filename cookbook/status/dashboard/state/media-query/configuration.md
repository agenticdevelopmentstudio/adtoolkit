
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Query | string | none (required) | CSS media query to evaluate and track, for example `"(max-width: 760px)"`. |
| Initial / server-render value | boolean | `false` | Hardcoded; not caller-configurable. |
| Media-query facility | environment capability | the platform's built-in media-query facility | Read from the global environment, not injected; tests replace it with a stand-in. |

