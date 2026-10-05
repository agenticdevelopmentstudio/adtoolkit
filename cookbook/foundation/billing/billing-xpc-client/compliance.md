
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. unit-test-coverage is partial: `BillingXPCClientTests` covers the write bound and no-retry, stored values, refusal sentences, unreachable and unreadable, read-failed rows, negative counts, the preferences push and the reply decoder. No test covers a failing list read (vector 002), a zero count (vector 010), a successful delete, `billingOverview`, the entry filters, the 5-second preferences timeout or the default preferences push.

