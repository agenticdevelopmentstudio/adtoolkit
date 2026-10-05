
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | partial | Performance |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | partial | Reliability |

`separation-of-concerns` **passed**: each of the three pieces has exactly one
job — `AppleScriptRunner` only compiles/executes AppleScript source and
structures the outcome, `MainActorScriptCommand` only bridges Cocoa
Scripting's dispatch onto the main actor, and `applicationElementSpecifier`
only builds one kind of `NSScriptObjectSpecifier` — with no UI, persistence,
or networking code mixed into any of them. `unit-test-coverage` is
**partial**: `AppleScriptRunner` and `MainActorScriptCommand` each have a
dedicated `Tests/.../Scripting/*Tests.swift` suite with meaningful
assertions (see Conformance Test Vectors), but `applicationElementSpecifier`
has no test file among the given sources or found elsewhere in the
repository. `explicit-error-handling` **passed**: `AppleScriptRunner.run(_:)`
never drops a compile or runtime failure — every failure path returns a
distinct, inspectable `Result` case; nothing is caught and discarded.
`main-thread-freedom` is **partial**: `AppleScriptRunner.run(_:)` executes
synchronously and can block whichever thread calls it for the duration of
the AppleScript's execution, with no timeout and no async variant; the
component leaves avoiding a main-thread block entirely to the caller (see
`caller-main-thread-marshaling`). `fault-tolerance` is **partial**:
`applicationElementSpecifier` degrades safely to `nil` when its AppKit
dependency is in an unexpected state, but it and
`MainActorScriptCommand.performDefaultImplementation()` both trap via
`MainActor.assumeIsolated` if ever invoked off the main thread — a
deliberate fail-fast choice (see Design Decisions) that satisfies
agenticdevelopercookbook://principles/fail-fast but not this check's literal
"without crashing" bar.

