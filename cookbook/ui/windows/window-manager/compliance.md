
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [health-observability](agenticdevelopercookbook://compliance/reliability#health-observability) | partial | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |

separation-of-concerns passes because frame persistence (`WindowFrameManager`), live lookup (`WindowRegistry`), storage (`WindowStateStorage` and its two implementations), key namespacing (`WindowStateNamespace`) and capture (`WindowScreenshot`) are separate types behind a thin coordinator. unit-test-coverage is partial: the termination latch, recent-limit mirror, factory execution, registry visibility, namespace isolation, the reopen policy, the missing-factory clear and screenshot failure paths have tests, but `reopenRecentsOnLaunch()` and `windowDidInteract(_:kind:)` do not. explicit-error-handling fails because storage encode/decode failures and document-open failures are discarded without a signal (the open questions on storage-codec-failure and reopen-open-failure). data-integrity is partial because corrupt stored state reads as never-saved and is overwritten, and the two storage implementations disagree on a non-boolean visibility value. state-recovery passes because frames and visibility persist across launches and `restoreOnLaunch()` replays them. graceful-degradation passes because a headless run skips reopen, a missing capture symbol yields `nil`, and an empty window ID is ignored. health-observability passes because the missing-factory wiring gap is logged under every storage backend. main-thread-freedom passes because every main-actor operation is bounded by the number of window IDs or recent documents, and document opening is asynchronous. no-pii-in-logs passes because the single log line carries only a host-chosen window ID. data-minimization passes because the namespace stores a hash instead of the bundle path.

