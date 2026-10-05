
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| storage-key prefix | `string` (via the data-configuration setter) | the host's namespace (the web implementation ships `'adh'`; see Platform Notes) | Prefix for every FTD key (`<prefix>:ftd:...`) and the cached-workspace key (`<prefix>:home:workspace`) |
| workspace-list cache key | exported constant | `('workspaces')` | Cache key the workspace switcher's own list is cached under |
| workspace-list-changed event name | exported constant | a fixed name, `<namespace>:workspaces-changed` (see Platform Notes) | Name of the event the workspace-list-changed announcement operation broadcasts |
| resource cache-retention period | imported constant (defined alongside the shared cache, not one of this component's own files) | `1,800,000` ms (30 min) | Retention period every resource-list/resource-item entry this component mints uses |
| `reportErrors` | caller-supplied option, per call to the resource-item/resource-list read state | `true` | Gates whether a load failure is sent to the failure-reporting sink |
| `seedFrom` | caller-supplied option, per call to the resource-item read state | `undefined` | Supplies a placeholder value (never treated as settled) while the real read is in flight |

