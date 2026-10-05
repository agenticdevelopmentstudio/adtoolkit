
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `gate` | `AuthGate` (from `../auth/port`) | required, caller-supplied | The credential resolver `requireAuth` wraps; injected per app, not read from environment by these two files. |
| `opts.max` | `number` | required, no default | Ceiling on requests per key per window before `rateLimit` starts responding `429`. Caller-supplied per mount point — `10` for `/auth/login`, `5` for `/auth/signup` in this backend's own wiring. |
| `opts.windowMs` | `number \| undefined` | `60000` (60 seconds) via `?? 60_000` | Fixed-window length in milliseconds for one `rateLimit(opts)` instance. |
| `MAX_BUCKETS` | module constant (`rate-limit.ts`) | `50_000` | Hard ceiling on distinct keys one `rateLimit` instance holds at once before its sweep drops the whole table. Not configurable per call. |
| `'admin'` tier literal | hardcoded string (`requireAdmin`) | fixed | The one tier value `requireAdmin` admits; not a configurable threshold. |

