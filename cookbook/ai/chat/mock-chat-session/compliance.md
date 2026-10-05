
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

Notes: no-hardcoded-strings fails because the default `reply`, `"This is a mock reply."`, is a hardcoded English literal with no localization mechanism (see Localization). unit-test-coverage is partial because `MockChatSessionTests.swift` contains exactly one test, covering only the happy-path scripted reply (dev-chat-model-002 above); it exercises neither `interrupt()`, `close()`, an empty `reply`, a non-positive `chunkSize`, nor a second `events()` subscription. data-integrity is partial because of the unsynchronized `liveTurn` access recorded under **live-turn-synchronization** — a `var` mutated and read from multiple call sites with no lock, on a type declared `@unchecked Sendable`.

`separation-of-concerns` passes because `MockChatSession` only scripts a canned reply as chunked response events for the chat-session contract; it does no I/O, owns no transcript state and leaves reduction of events to `ChatTranscriptReducer`.

