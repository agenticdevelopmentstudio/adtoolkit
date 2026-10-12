import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Stenographer never asks for Accessibility, and an app without that grant
/// that so much as checks for it (`AXIsProcessTrusted()`) stalls tccd — and
/// the whole machine — for ~10s. The Sessions window's list is where that
/// check used to come from, so its opt-out is pinned here, on Stenographer's
/// side, where a toolkit bump that changes the default can't reach it.
@MainActor
final class SessionsWindowAccessibilityTests: XCTestCase {

    func testTheSessionsListNeverUsesAccessibility() {
        let source = StenographerSessionListSource(service: StubDaemonService(), sinceHours: 0)
        let controller = SessionsWindowController.makeListViewController(source: source)

        XCTAssertFalse(controller.viewModel.usesAccessibility)
        XCTAssertFalse(controller.viewModel.actionHandler.usesAccessibility)
    }
}
