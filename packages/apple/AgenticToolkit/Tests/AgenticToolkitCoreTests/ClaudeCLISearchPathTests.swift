import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite struct ClaudeCLISearchPathTests {
    let home = URL(fileURLWithPath: "/Users/jane")

    @Test func binaryDirectoryLeadsThePath() {
        let path = ClaudeCLI.searchPath(
            claudeDirectory: ClaudeCLI.directory(ofBinary: "/Users/jane/.nvm/versions/node/v22.3.0/bin/claude"),
            home: home, inheritedPath: "/usr/bin:/bin")
        #expect(path == "/Users/jane/.nvm/versions/node/v22.3.0/bin:/Users/jane/.local/bin:"
            + "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin")
    }

    @Test func directoryOfBinaryDropsTheFileName() {
        #expect(ClaudeCLI.directory(ofBinary: "/opt/homebrew/bin/claude") == "/opt/homebrew/bin")
    }

    @Test func repeatedDirectoriesKeepOnlyTheirFirstPlace() {
        let path = ClaudeCLI.searchPath(
            claudeDirectory: "/usr/local/bin", home: home,
            inheritedPath: "/opt/homebrew/bin:/usr/bin:/usr/bin:/Users/jane/.local/bin")
        #expect(path == "/usr/local/bin:/Users/jane/.local/bin:/opt/homebrew/bin:/usr/bin")
    }

    @Test func missingInheritedPathFallsBackToSystemDirectories() {
        let path = ClaudeCLI.searchPath(home: home, inheritedPath: nil)
        #expect(path == "/Users/jane/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin")
    }
}
