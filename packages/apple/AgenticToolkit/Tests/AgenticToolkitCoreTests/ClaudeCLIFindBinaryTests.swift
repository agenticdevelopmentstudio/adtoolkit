import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite struct ClaudeCLIFindBinaryTests {
    let home = URL(fileURLWithPath: "/Users/Jane Smith")

    @Test func prefersLocalBin() {
        let found = ClaudeCLI.findBinary(home: home, environment: [:]) {
            $0 == "/Users/Jane Smith/.local/bin/claude" || $0 == "/usr/local/bin/claude"
        }
        #expect(found == "/Users/Jane Smith/.local/bin/claude")
    }

    @Test func findsVolta() {
        let found = ClaudeCLI.findBinary(home: home, environment: [:]) { $0 == "/Users/Jane Smith/.volta/bin/claude" }
        #expect(found == "/Users/Jane Smith/.volta/bin/claude")
    }

    @Test func findsBun() {
        let found = ClaudeCLI.findBinary(home: home, environment: [:]) { $0 == "/Users/Jane Smith/.bun/bin/claude" }
        #expect(found == "/Users/Jane Smith/.bun/bin/claude")
    }

    @Test func findsNpmPrefixFromEnvironment() {
        let found = ClaudeCLI.findBinary(home: home, environment: ["NPM_CONFIG_PREFIX": "/opt/npm"]) {
            $0 == "/opt/npm/bin/claude"
        }
        #expect(found == "/opt/npm/bin/claude")
    }

    @Test func findsNewestNvmNode() {
        let found = ClaudeCLI.findBinary(
            home: home, environment: [:],
            isExecutable: { $0 == "/Users/Jane Smith/.nvm/versions/node/v22.3.0/bin/claude" },
            listDirectory: { path in
                path == "/Users/Jane Smith/.nvm/versions/node" ? ["v18.1.0", "v22.3.0", "v20.0.0"] : []
            })
        #expect(found == "/Users/Jane Smith/.nvm/versions/node/v22.3.0/bin/claude")
    }

    @Test func findsFnmInstallationWithSpacesInPath() {
        let root = "/Users/Jane Smith/Library/Application Support/fnm/node-versions"
        let found = ClaudeCLI.findBinary(
            home: home, environment: [:],
            isExecutable: { $0 == "\(root)/v20.0.0/installation/bin/claude" },
            listDirectory: { $0 == root ? ["v18.1.0", "v20.0.0"] : [] })
        #expect(found == "\(root)/v20.0.0/installation/bin/claude")
    }

    @Test func nilWhenNothingFound() {
        #expect(ClaudeCLI.findBinary(home: home, environment: [:]) { _ in false } == nil)
    }

    @Test func sortedVersionsIsNumericNewestFirst() {
        #expect(ClaudeCLI.sortedVersions(["v9.0.0", "v10.0.0", "v2.1.0"]) == ["v10.0.0", "v9.0.0", "v2.1.0"])
        #expect(ClaudeCLI.sortedVersions(["v18.1.0", "v22.3.0", "v20.0.0"]) == ["v22.3.0", "v20.0.0", "v18.1.0"])
    }

    @Test func sortedVersionsToleratesNonNumericEntries() {
        let sorted = ClaudeCLI.sortedVersions([".DS_Store", "v9.0.0", "v10.0.0"])
        #expect(sorted.count == 3)
        #expect(sorted.first == "v10.0.0")
        #expect(ClaudeCLI.sortedVersions([]) == [])
    }
}
