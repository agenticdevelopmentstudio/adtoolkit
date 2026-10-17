import XCTest
@testable import AgenticToolkitCore

/// `ProcessEnv`'s pid→token memo bounds itself.
///
/// The behaviour under test is invisible from the outside: every lookup returns
/// the same answer whether or not the dead pids beside it were ever evicted, so
/// only the entry count can tell a bounded cache from a growing one. That is
/// exactly why it went unbounded — a 30s TTL checked on *read* never evicts an
/// entry nothing reads again, and hook pids are never looked up twice.
final class ProcessEnvCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ProcessEnv.resetCacheForTesting()
    }

    override func tearDown() {
        ProcessEnv.resetCacheForTesting()
        super.tearDown()
    }

    /// Pids chosen to be above the kernel's pid ceiling so no live process can
    /// answer: the walk terminates immediately and caches the empty result,
    /// which is the case that used to accumulate.
    private func lookup(_ count: Int) {
        for offset in 0..<count {
            _ = ProcessEnv.oauthTokenWalkingUp(from: Int32(2_000_000 + offset))
        }
    }

    func testCacheStaysAtOrBelowItsCeilingUnderABurstOfDistinctPids() {
        lookup(ProcessEnv.maxEntries * 4)
        XCTAssertLessThanOrEqual(
            ProcessEnv.cachedTokenCountForTesting,
            ProcessEnv.maxEntries,
            "a burst of short-lived hook pids must not grow the cache without limit"
        )
    }

    func testEvictionOnlyStartsOnceTheCeilingIsReached() {
        // The bound must not cost the cache its purpose: below the ceiling every
        // entry is still there to be hit.
        let belowCeiling = ProcessEnv.maxEntries / 2
        lookup(belowCeiling)
        XCTAssertEqual(ProcessEnv.cachedTokenCountForTesting, belowCeiling)
    }

    func testRepeatedLookupsOfOnePidCacheOneEntry() {
        lookup(1)
        for _ in 0..<50 { _ = ProcessEnv.oauthTokenWalkingUp(from: 2_000_000) }
        XCTAssertEqual(
            ProcessEnv.cachedTokenCountForTesting, 1,
            "a repeated lookup is a cache hit, not a new entry"
        )
    }
}
