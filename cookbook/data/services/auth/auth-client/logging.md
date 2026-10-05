
Subsystem: `agentictoolkit` | Category: `auth-client`

| Event | Level | Message |
|-------|-------|---------|
| Refresh network/parse failure | error (via unconditional error reporting, always reaches the console) | Reported with `{ feature: 'auth', step: 'tokenRefresh' }` |
| Any reported auth error (unconditional path) | error | Logged with the error and its context |
| Missing AS base at build/runtime (logged once per page load) | error | `'[adh-auth] NEXT_PUBLIC_AUTH_API_URL was not set when this site was built...'` |

No part of this component logs at an informational or warning level — every
log call site is an error-level report, and every one is either an
unexpected-failure report or the one-time misconfiguration notice above. The
error-status gate (**report-unexpected-status-gate**) is specifically what
keeps an expected 4xx (wrong password, stale code) off this log.

