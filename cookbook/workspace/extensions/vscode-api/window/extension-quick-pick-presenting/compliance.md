
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because this file's only responsibility is declaring the contract — two plain data types and a single-method protocol — with no presentation logic, no AppKit dependency, and no networking or persistence of its own; it was split out of `MainThreadWindow.swift` specifically to keep that file from growing further, and is declared apart from `ExtensionMessagePresenting` on an explicit interface-segregation rationale (see Overview and Design Decisions). `unit-test-coverage` is partial: every runtime-observable behavior in this contract — the `nil`-vs-`[]` distinction, index-based (not label-based) selection, answer-order preservation, separator field defaulting, and highlight forwarding — has a direct test among the given sources (see Conformance Test Vectors 001–009, 011), but the two purely structural requirements about calling discipline and actor/type constraints (**presenting-highlight-after-return-prohibited**, **presenting-single-context-execution**, **presenting-class-only**, **presenting-single-requirement**, the **item-thread-safe-equatable**/**request-thread-safe-equatable** guarantees) are verified by code inspection or by the compiler rather than by a dedicated runtime assertion in the given test files.

