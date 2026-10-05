
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config.mcpAllowedHosts` | `readonly string[]` (`StatusConfig` field) | host-supplied | Additional hostnames the `/mcp` transport's DNS-rebinding guard accepts, appended to the always-present `'localhost'`/`'127.0.0.1'`. |
| `config.monitorLabel` | `string` (`StatusConfig` field) | host-supplied | This monitor's own label, passed to `assembleFleet` by `get_fleet` so the fleet view can identify which member is "self." |
| `config.credentials` / `config.secrets` | `Readonly<Record<string, string \| undefined>>` (`StatusConfig` fields) | host-supplied | Platform provider credentials `run_auto_configure`/`configure_telemetry` pass through to `performAutoConfigure`/`collectTelemetry`; never the caller's own MCP bearer. |
| `MCP_PATH` | module constant (`route.ts`) | `'/mcp'` | The one fixed path `mountMcp` registers; not configurable per call. |
| `tier` | `Tier` (`'view' \| 'admin'`), read from `c.get('tier')` | resolved upstream by `requireAuth` | Determines `selectTools(tier)`'s registration set and every handler's layer-2 re-check; these three files never resolve it themselves. |
| `storage` | injected `Storage` port | required | Every tool's `execute` reads or writes through this port; its implementation is external to these three files. |

