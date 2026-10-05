
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| input row | a row (see Status Row Model) | none (required) | The status-board row passed to the detail-building function. |
| input row detail | the row detail shape | none (required) | The detail passed to the serialization function. |
| non-deploy platform set | a fixed set of platform strings | `crunchy`, `glitchtip` | Platforms that never get a deploy outcome. Changing it requires a source edit. |
| platform label function | dependency | specified in Deploy Display | Supplies the platform name before lower-casing. |
| host-extraction function | dependency | see Platform Notes | Supplies the endpoint title from its URL. |

This logic reads no environment variables and no settings keys, and takes no other injected dependencies.

