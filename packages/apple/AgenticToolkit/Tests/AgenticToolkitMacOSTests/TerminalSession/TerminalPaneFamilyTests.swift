import XCTest
import AIPluginKit
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Every pane the family registers is one it allows, and the other way round —
/// a registered pane with no allowance is never offered, and an allowance with
/// no registration fails the spec's validation.
@MainActor
final class TerminalPaneFamilyTests: XCTestCase {

    private func vault() -> PrivacyWordsVault {
        PrivacyWordsVault(store: PrivacyWordStore(
            accessGroup: nil, service: "com.agenticdevelopmentstudio.privacy-words.tests"))
    }

    private func pluginManager() -> AIPluginManager {
        AIPluginManager(searchPaths: [FileManager.default.temporaryDirectory
            .appendingPathComponent("TerminalPaneFamilyTests-\(UUID().uuidString)")])
    }

    func testTheBareFamilyIsTerminalsAndTerminalChats() {
        let family = TerminalPaneFamily(preferredAxis: .vertical)
        XCTAssertEqual(family.allowances.map(\.viewID), [.terminal, .terminalChat])
    }

    func testTheWholeFamilyAddsPrivateTerminalsAndPersonaChats() {
        let family = TerminalPaneFamily(preferredAxis: .vertical, pluginManager: pluginManager(),
                                        privacyVault: vault())
        XCTAssertEqual(family.allowances.map(\.viewID),
                       [.terminal, .privateTerminal, .terminalChat, .personaTerminalChat])
        XCTAssertTrue(family.allowances.allSatisfy { $0.preferredAxis == .vertical })
    }

    func testEveryAllowanceIsRegistered() throws {
        let family = TerminalPaneFamily(preferredAxis: .horizontal, pluginManager: pluginManager(),
                                        privacyVault: vault())
        let registry = ComposableTabsViewRegistry()
        family.register(in: registry)
        let spec = ComposableTabLayoutSpec.split(
            axis: .horizontal, children: [.pane(.terminal)],
            allows: family.allowances + [.unbounded(.placeholder)])
        XCTAssertNoThrow(try spec.validate(against: registry))
    }
}
