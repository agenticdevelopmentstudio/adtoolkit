
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| language-services-lsp-001 | start-is-idempotent-and-joined | Two concurrent starts of an idle session | Exactly one process spawn; both callers see the same outcome |
| language-services-lsp-002 | start-after-stop-refused | Starting the session after stopping it has completed | Throws a stopped-session error |
| language-services-lsp-003 | concurrent-start-propagates-shared-failure | Two concurrent starts where the shared attempt fails | Both callers throw the same reported failure |
| language-services-lsp-004 | capabilities-only-while-running | Reading the session's capabilities while its state is starting | Returns nothing |
| language-services-lsp-005 | capabilities-go-nil-after-spontaneous-death | Reading the session's capabilities after a running server exits on its own | Returns nothing |
| language-services-lsp-006 | stop-idempotent | Stopping the session twice in a row while it is running | Second call is a no-op; teardown runs exactly once |
| language-services-lsp-007 | stop-preserves-failed-state | Stopping a session already in the failed state | State remains failed, not stopped |
| language-services-lsp-008 | initialize-request-framed-once | A session start against a scripted server | Exactly one `initialize` request frame is sent |
| language-services-lsp-009 | initialize-declares-only-honourable-capabilities | Inspect the declared client capabilities' semantic-token/completion flags | `snippetSupport`, `commitCharactersSupport`, `overlappingTokenSupport`, `multilineTokenSupport` are all `false` |
| language-services-lsp-010 | truncated-frame-fails-session | A scripted server that truncates its response mid-body | Session start fails with the transport/framing error |
| language-services-lsp-011 | unasked-exit-is-a-failure | A scripted server that exits cleanly without stopping being called for | Session state becomes failed, not stopped |
| language-services-lsp-012 | stop-during-start-does-not-orphan | Stopping the session while it is still spawning | Call returns without crashing; no orphaned child process remains |
| language-services-lsp-013 | user-config-replaces-not-merges-builtin | A user configuration for `swift` alongside the built-in SourceKit-LSP | Effective configuration for `swift` is the user's, wholesale |
| language-services-lsp-014 | unrelated-builtin-survives | A user configuration for `python` only | Built-in `swift`/`objective-c`/`c`/`cpp` configuration is untouched |
| language-services-lsp-015 | root-marker-walk-innermost-first | A file two directories below a `.git`-marked root that is itself below another `.git` | Walk resolves to the nearer (innermost) marker directory |
| language-services-lsp-016 | marker-order-does-not-affect-root | `["*.xcodeproj", ".git"]` vs `[".git", "*.xcodeproj"]` on the same tree | Both orders resolve to the same root directory |
| language-services-lsp-017 | unmatched-marker-resolves-nil | Markers that exist nowhere on the ancestor chain | The workspace root resolves to nothing |
| language-services-lsp-018 | secret-change-triggers-replacement | A settings write changing one server's secret env value | Its session is torn down and restarted with the new secret in its environment |
| language-services-lsp-019 | disabling-tears-down-session | Enablement flipped from `true` to `false` for a configuration | Its running session is stopped and removed |
| language-services-lsp-020 | observe-state-refuses-second-observer | Observing a session's state twice for the same live session id | Second call logs at fault level and returns failure |
| language-services-lsp-021 | retired-session-late-transition-cannot-overwrite | A retired session emits a late state transition after its replacement is running | The published session-state table still reflects the replacement, unchanged |
| language-services-lsp-022 | settings-write-during-shutdown-starts-nothing | A configuration change delivered mid-shutdown | No new session is started |
| language-services-lsp-023 | per-session-ordered-queue | Enqueueing opened, edited, saved, closed events in that order | Server receives the four notifications in the same order |
| language-services-lsp-024 | open-close-defaults-true | A server capability response omitting `openClose` | The resolved sync capability's `openClose` resolves to `true` |
| language-services-lsp-025 | change-reopens-unopened-document | `didChange` forwarded for a document the server was never told is open | `didOpen` is sent first, then the `didChange` |
| language-services-lsp-026 | incremental-sync-forwards-verbatim | Resolved sync kind incremental, an edit with a 2-element change array | Server receives the same 2-element change array |
| language-services-lsp-027 | full-sync-forwards-whole-document | Resolved sync kind full, an edit to one line of a multi-line document | Server receives one `didChange` carrying the whole document text |
| language-services-lsp-028 | failed-start-pipeline-forwards-nothing | A pipeline whose session start throws | No `didOpen`/`didChange`/`didSave`/`didClose` reaches the server |
| language-services-lsp-029 | open-close-disabled-still-sends-change | Resolved capability with `openClose == false`, one edit | No `didOpen`/`didClose` sent; `didChange` is still sent |
| language-services-lsp-030 | replay-matches-claimed-language-only | A newly connected `swift`-only session with one open `swift` and one open `python` document | Only the `swift` document is replayed |
| language-services-lsp-031 | out-of-scope-documents-silently-excluded | An edit to a document outside the workspace root | No `didOpen`/`didChange` notification is sent to any session |
| language-services-lsp-032 | scope-check-resolves-symlinks | A workspace root reached only through a symlink, and a document under its resolved path | Document is classified in scope |
| language-services-lsp-033 | string-prefix-sibling-excluded | Root `/work/App` and document under `/work/AppOther/file.swift` | Document is classified out of scope |
| language-services-lsp-034 | out-of-scope-refusals-counted-once-per-batch | A seeding pass refusing 3 out-of-scope documents | Exactly one divergence-ledger entry recording the count |
| language-services-lsp-035 | observe-is-idempotent-per-session | Beginning to observe the same session twice | Only one consumer of that session's published-diagnostics stream is started |
| language-services-lsp-036 | stale-diagnostics-never-dropped | A diagnostics publish with `version: nil` | Diagnostics for that URI are stored, not discarded |
| language-services-lsp-037 | empty-diagnostics-clears-not-ignored | An empty diagnostics array published for a URI already holding diagnostics | Stored diagnostics for that URI become empty |
| language-services-lsp-038 | document-diagnostics-pruned-on-close | A close event dropping a document's reference count to zero in the document store | Stored diagnostics for that URI are removed |
| language-services-lsp-039 | shutdown-idempotent-preserves-diagnostics | Shutting the diagnostics store down twice while it holds diagnostics | Second call is a no-op; diagnostics remain readable |
| language-services-lsp-040 | secrets-stored-in-keychain-not-plain-settings | Inspect the persisted secrets setting's declared provider | Declared secure, routed to the platform's secure credential storage |
| language-services-lsp-041 | stream-end-handler-called-exactly-once | A channel whose underlying process exits | The stream-end handler fires exactly once, with the exit condition |

