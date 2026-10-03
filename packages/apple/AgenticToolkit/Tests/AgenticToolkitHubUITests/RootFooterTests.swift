import AgenticDeveloperHubClient
import AgenticToolkitHubService
import AppKit
import XCTest
@testable import AgenticToolkitHubUI

/// Review focus 4: the status footer replaces the hand-built strip, and with
/// no message it is hidden and reported as absent — not as an empty string a
/// script would read as "the strip says nothing".
@MainActor
final class RootFooterTests: XCTestCase {

    /// Pinned to a reachable daemon: the default source probes the real one,
    /// and on a machine with no adh-daemon running the strip rightly says
    /// "Daemon offline" — which is the next test, not this one.
    func testFooterHasTheSharedIdentifierAndStartsHidden() async throws {
        let composition = await HubAppComposition.macOS(
            sessionStore: InMemorySessionStore(),
            transportSource: StaticTransportSource(.daemon())
        )
        let root = RootViewController(composition: composition)
        _ = root.view
        let label = try XCTUnwrap(Self.find("root.footer.status", in: root.view))
        XCTAssertTrue(label.isHiddenOrHasHiddenAncestor)
        XCTAssertNil(root.scriptStatusStripMessage)
    }

    func testFooterShowsTheOfflineMessageWhenNoDaemonAnswers() async throws {
        let composition = await HubAppComposition.macOS(
            sessionStore: InMemorySessionStore(),
            transportSource: StaticTransportSource(.direct(transport: StubClientTransport()))
        )
        let root = RootViewController(composition: composition)
        _ = root.view
        let label = try XCTUnwrap(Self.find("root.footer.status", in: root.view))
        XCTAssertFalse(label.isHiddenOrHasHiddenAncestor)
        XCTAssertEqual(root.scriptStatusStripMessage, StatusStripState.daemonOfflineMessage)
    }

    private static func find(_ identifier: String, in view: NSView) -> NSView? {
        if view.accessibilityIdentifier() == identifier { return view }
        for subview in view.subviews {
            if let found = find(identifier, in: subview) { return found }
        }
        return nil
    }
}
