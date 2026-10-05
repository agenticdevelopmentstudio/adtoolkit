
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | passed | Reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | passed | Reliability |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |

`separation-of-concerns` **passed**: each of the eight files owns one
concern — process/transport (`LanguageServerChannel`), one server's
lifecycle (`LanguageServerSession`), fleet reconciliation
(`LanguageServerRegistry`), per-session document forwarding
(`DocumentSyncPipeline`), workspace-scope/replay coordination
(`LanguageServerDocumentSync`), diagnostics aggregation (`DiagnosticStore`),
and configuration/settings shape (`LanguageServerConfiguration`,
`LanguageServerSettings`) — with dependencies pointing one way, from session
up through registry and document sync. `unit-test-coverage` **passed**:
every file has a dedicated test file (`DiagnosticStoreTests`,
`LanguageServerSessionTests`, `LanguageServerSessionRaceTests`,
`LanguageServerRegistryTests`, `LanguageServerDocumentSyncTests`,
`LanguageServerDocumentSyncScopeTests`,
`FakeLanguageServerSessionFidelityTests`) covering ordering, concurrency,
and failure paths, not just the happy path. `explicit-error-handling`
**passed**: every failure path surfaces a typed `LanguageServerSessionError`/`LanguageServerFailure`
or is logged with an explicit level (debug for `.notRunning`, error
otherwise) — no path silently swallows a primary operation's failure.
`error-recovery` **passed**: `start()`'s join-in-flight behavior, the
first-cause-wins failure diagnosis, and `reconcile`'s diff-and-replace
model all exist specifically to keep concurrent and transient failures from
corrupting session or registry state. `timeout-handling` **passed**: every
teardown step (abandoned-start, outstanding-request, graceful-shutdown,
exit-status) runs under an explicit wall-clock budget rather than waiting
indefinitely. `secure-storage` **passed**: per-server secrets are declared
`isSecure: true` and routed to the Keychain, never the plain settings
provider. `input-sanitization` is **partial**: workspace-scope checks
(`isInWorkspaceScope`) validate document paths against the resolved
workspace root, but `LanguageServerConfiguration.command` itself is not
validated to be an absolute path before being handed to the process spawn
(see `command-path-not-validated` above) — an accepted gap in the source,
not a hidden one.

