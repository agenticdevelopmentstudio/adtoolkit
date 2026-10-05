
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | passed | performance |

The hook separates fetching (two private query hooks), classification (the engine plus the app's paused fold in `lib/config-status`) and model assembly (the pure `buildStatus`), and keeps the roster query private so there is one access point. Unit coverage exists in `use-config-status.dom.test.tsx` for the scan-failure and both-loaded paths, but not for `enabled: false`, `refetch`, `invalidateConfigQueries`, the paused fold through this hook, or the per-platform tally, hence partial. Error handling is explicit for a single failure, but when both queries fail only the roster error is returned, and a malformed classification body is cast rather than validated and throws during render, hence partial. Caching uses shared react-query keys, a joint invalidation helper, and the server's 30-second cache instead of a polling interval.

