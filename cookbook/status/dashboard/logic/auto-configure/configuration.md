
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Port adapter's client | API client | none (required) | Client forwarded to every monitoring-configuration client call |
| Port adapter's backing implementation | monitoring-configuration client module | the real monitoring-configuration client | Backing functions; tests inject a fake module |
| Match operation's input list | list of project descriptors | none (required) | Projects to match, applied in list order |
| Match operation's supplied port | engine port contract | built from the supplied client | Injected engine port; takes precedence over a supplied client |
| Match operation's supplied client | API client | none | Required when no port is supplied; no hidden default |
| Match operation's live-project index | engine-defined shape | none | Live-project index forwarded to the planner |
| Match operation's progress callback | callback receiving `(done, total)` | none | Per-project progress callback |
| Shared row cap | number constant | `5` | Row cap shared by both detail-block builders |

No environment variables or settings keys are read.

