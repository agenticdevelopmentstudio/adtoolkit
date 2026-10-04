#if os(macOS)
import XCTest
import AgenticToolkitPermissions
@testable import AgenticToolkitActivity

/// Records what it was asked and answers a script, so the mapping can be
/// tested without touching the real TCC database.
///
/// `status` and `request` answer from **separate** scripts and keep separate
/// call logs. That separation is the point: a checker whose `request` merely
/// forwarded to its `status` answers identically either way, and a gate that
/// quietly checked the status where it was meant to prompt — never raising
/// the consent dialog the owner is waiting on — would pass every assertion
/// here unnoticed.
///
/// `@unchecked Sendable` guarded by a lock, the same idiom as
/// `MutableFakePermissionGate` in `ContextFakes.swift`, because
/// `PermissionChecking` is called across an `await`.
private final class ScriptedChecker: PermissionChecking, @unchecked Sendable {
    private let lock = NSLock()
    private let statuses: [String: PermissionStatus]
    private let grants: [String: PermissionStatus]
    private var statusCalls: [String] = []
    private var requestCalls: [String] = []

    init(statuses: [String: PermissionStatus] = [:],
         grants: [String: PermissionStatus] = [:]) {
        self.statuses = statuses
        self.grants = grants
    }

    /// Every permission this checker was consulted about, by either method.
    var consulted: [String] { lock.withLock { statusCalls + requestCalls } }

    /// Only the permissions it was asked to *prompt* for.
    var asked: [String] { lock.withLock { requestCalls } }

    func status(_ permission: Permission) async -> PermissionStatus {
        lock.withLock { statusCalls.append(permission.displayName) }
        return statuses[permission.displayName] ?? .undetermined
    }

    @discardableResult
    func request(_ permission: Permission) async -> PermissionStatus {
        lock.withLock { requestCalls.append(permission.displayName) }
        return grants[permission.displayName] ?? .undetermined
    }
}

final class MacPermissionGateTests: XCTestCase {
    func testNoneIsAlwaysGrantedWithoutConsultingTheSystem() async {
        let checker = ScriptedChecker()
        let gate = MacPermissionGate(checker: checker)
        let state = await gate.status(.none)
        XCTAssertEqual(state, .granted, "a trigger needing nothing must never be blocked")
        XCTAssertEqual(checker.consulted, [],
                       "and the system is never asked about a permission that does not exist")
    }

    func testMapsAccessibilityAndLocationOntoTheToolkitPermissions() {
        XCTAssertEqual(MacPermissionGate.toolkitPermission(for: .accessibility), .accessibility)
        XCTAssertEqual(MacPermissionGate.toolkitPermission(for: .location), .location)
        XCTAssertNil(MacPermissionGate.toolkitPermission(for: .none))
    }

    func testStatusTranslatesEveryToolkitStatus() async {
        // Each checker's prompt script says the opposite of its status one,
        // so a `status` that prompted would answer wrongly rather than
        // identically.
        let granted = MacPermissionGate(
            checker: ScriptedChecker(statuses: ["Location": .granted],
                                     grants: ["Location": .denied]))
        await XCTAssertEqualAsync(await granted.status(.location), .granted)

        let denied = MacPermissionGate(
            checker: ScriptedChecker(statuses: ["Location": .denied],
                                     grants: ["Location": .granted]))
        await XCTAssertEqualAsync(await denied.status(.location), .denied)

        let undetermined = MacPermissionGate(
            checker: ScriptedChecker(grants: ["Accessibility": .granted]))
        await XCTAssertEqualAsync(await undetermined.status(.accessibility), .undetermined)
    }

    /// Asking and prompting both answer a `ContextPermissionState`, so the
    /// answer alone cannot say which one happened. Only the checker's record
    /// of what it was called can, and the difference is the whole user-facing
    /// behaviour: a dialog appears, or it does not.
    func testStatusLooksAtThePermissionRatherThanPromptingForIt() async {
        let checker = ScriptedChecker(statuses: ["Location": .granted])
        let gate = MacPermissionGate(checker: checker)
        await XCTAssertEqualAsync(await gate.status(.location), .granted)
        XCTAssertEqual(checker.asked, [],
                       "reading the status must never raise a consent dialog")
    }

    func testRequestTranslatesEveryToolkitStatusAndNeverConsultsTheSystemForNone() async {
        // As above, the two scripts disagree, so a request that only read the
        // status would be caught by the answer as well as by the record.
        let granted = MacPermissionGate(
            checker: ScriptedChecker(statuses: ["Location": .denied],
                                     grants: ["Location": .granted]))
        await XCTAssertEqualAsync(await granted.request(.location), .granted)

        let denied = MacPermissionGate(
            checker: ScriptedChecker(statuses: ["Location": .granted],
                                     grants: ["Location": .denied]))
        await XCTAssertEqualAsync(await denied.request(.location), .denied)

        let undetermined = MacPermissionGate(
            checker: ScriptedChecker(statuses: ["Accessibility": .granted]))
        await XCTAssertEqualAsync(await undetermined.request(.accessibility), .undetermined)

        let noneChecker = ScriptedChecker()
        let none = MacPermissionGate(checker: noneChecker)
        await XCTAssertEqualAsync(await none.request(.none), .granted)
        XCTAssertEqual(noneChecker.consulted, [],
                       "a trigger needing no permission must raise no dialog")
    }

    /// The mirror of `testStatusLooksAtThePermissionRatherThanPromptingForIt`,
    /// and the more damaging direction: a request that silently checked the
    /// status would leave an undetermined permission undetermined forever,
    /// with the owner waiting on a dialog that is never shown.
    func testRequestPromptsRatherThanOnlyLookingAtTheStatus() async {
        let checker = ScriptedChecker(grants: ["Location": .granted])
        let gate = MacPermissionGate(checker: checker)
        await XCTAssertEqualAsync(await gate.request(.location), .granted)
        XCTAssertEqual(checker.asked, ["Location"])
    }
}

/// XCTAssertEqual's autoclosures are not async, so compare eagerly.
private func XCTAssertEqualAsync<T: Equatable>(_ a: T, _ b: T,
                                               file: StaticString = #filePath,
                                               line: UInt = #line) async {
    XCTAssertEqual(a, b, file: file, line: line)
}
#endif
