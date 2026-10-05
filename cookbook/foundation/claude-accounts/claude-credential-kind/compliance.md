
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because the type does exactly one thing, naming the credential kinds and their one key spelling, and holds no storage, network or UI of its own. `unit-test-coverage` is partial: no test file targets `ClaudeCredentialKind` directly; `AgenticToolkitMacOSTests/ClaudeAccounts/ClaudeLiveLoginRecordTests.swift` constructs accounts with each kind but does not assert the key or parse functions.

