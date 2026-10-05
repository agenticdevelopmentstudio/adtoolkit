
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |

`separation-of-concerns` passes because the type only describes the credential shape and the milliseconds-to-seconds view; custody (keychain) and evaluation (expiry policy) live in other layers. `unit-test-coverage` is partial: no test file targets `ClaudeOAuthCredential` directly. `AgenticToolkitMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` builds credentials and compares live to saved ones, so equality is exercised indirectly, but the seconds conversion and the optional-field defaults have no assertion.

