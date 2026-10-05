
This file uses no localization mechanism; it produces two hardcoded English string fragments that become part of an `IntegrationCheck`'s `detail` value returned in the `/integrations` API response and rendered on the integrations panel for any authenticated user — a user-facing string, not a server log line.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — recheck pending prefix | `recheck pending — <original detail>` | Prepended by suppressed-output-shape whenever a debounce-eligible failure has not yet met confirmation-threshold; `<original detail>` is the input check's own `detail`, produced elsewhere (e.g. `integrations.ts`'s provider checks). |
| n/a — connectivity detail | `<n> providers unreachable at once — likely monitor-side connectivity, not provider outages` | The synthetic `connectivity` check's `detail`, whenever correlated-downgrade applies; `<n>` is the confirmed count. |

