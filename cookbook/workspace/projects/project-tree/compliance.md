
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | Best Practices |

Notes: separation-of-concerns passes because `ProjectTree.swift` builds and
sorts an in-memory node graph only — no `NSOutlineView`, no `NSView`, and no
persistence or network code — leaving the tree's rendering entirely to
`ProjectBrowserViewController` and the `GitRepo` data shape to `GitRepo.swift`.
unit-test-coverage is partial because `ProjectTreeTests.swift` exercises
home-relative truncation, the outside-home leading slash, folder-before-project
sorting, registry-sourced naming, distinct-path folders, display order, and
the empty-input case (PT-001 through PT-008), but has no test for a duplicate
leaf path (PT-009) or for the folder/project path collision this recipe flags
as `project-tree-leaf-path-collision` (PT-010) — both are traced to the
source's control flow rather than to an assertion in the given suite.
good-test-properties passes because every test in `ProjectTreeTests.swift` is
a synchronous, `@MainActor`-isolated `XCTAssertEqual`/`XCTAssertTrue` call
against a locally constructed `[GitRepo]` array and a fixed `home` URL, with
no shared fixture, no I/O, and no ordering dependency between tests.

