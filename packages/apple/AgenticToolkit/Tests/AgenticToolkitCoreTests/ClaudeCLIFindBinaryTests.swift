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
        #expect(sorted == ["v10.0.0", "v9.0.0", ".DS_Store"])
        #expect(ClaudeCLI.sortedVersions([]) == [])
    }

    @Test func sortedVersionsComparesEachComponentNumerically() {
        #expect(ClaudeCLI.sortedVersions(["v22.3.0", "v22.10.0"]) == ["v22.10.0", "v22.3.0"])
    }

    @Test func npmPrefixTrailingSlashIsNormalized() {
        let found = ClaudeCLI.findBinary(home: home, environment: ["NPM_CONFIG_PREFIX": "/opt/npm/"]) {
            $0 == "/opt/npm/bin/claude"
        }
        #expect(found == "/opt/npm/bin/claude")
    }

    @Test func emptyNpmPrefixIsSkipped() {
        var withEmpty: [String] = []
        _ = ClaudeCLI.findBinary(home: home, environment: ["NPM_CONFIG_PREFIX": ""]) {
            withEmpty.append($0)
            return false
        }
        var withoutPrefix: [String] = []
        _ = ClaudeCLI.findBinary(home: home, environment: [:]) {
            withoutPrefix.append($0)
            return false
        }
        #expect(withEmpty == withoutPrefix)
    }

    @Test func findsLowercaseNpmConfigPrefix() {
        let found = ClaudeCLI.findBinary(home: home, environment: ["npm_config_prefix": "/opt/lower"]) {
            $0 == "/opt/lower/bin/claude"
        }
        #expect(found == "/opt/lower/bin/claude")
    }

    @Test func uppercaseNpmPrefixWinsOverLowercase() {
        let env = ["NPM_CONFIG_PREFIX": "/opt/upper", "npm_config_prefix": "/opt/lower"]
        let found = ClaudeCLI.findBinary(home: home, environment: env) {
            $0 == "/opt/upper/bin/claude" || $0 == "/opt/lower/bin/claude"
        }
        #expect(found == "/opt/upper/bin/claude")
    }

    @Test func findsClaudeLocal() {
        let found = ClaudeCLI.findBinary(home: home, environment: [:]) {
            $0 == "/Users/Jane Smith/.claude/local/claude"
        }
        #expect(found == "/Users/Jane Smith/.claude/local/claude")
    }

    @Test func findsNpmGlobal() {
        let found = ClaudeCLI.findBinary(home: home, environment: [:]) {
            $0 == "/Users/Jane Smith/.npm-global/bin/claude"
        }
        #expect(found == "/Users/Jane Smith/.npm-global/bin/claude")
    }

    @Test func earlierCandidateBeatsNvm() {
        let found = ClaudeCLI.findBinary(
            home: home, environment: [:],
            isExecutable: {
                $0 == "/opt/homebrew/bin/claude" || $0 == "/Users/Jane Smith/.nvm/versions/node/v22.3.0/bin/claude"
            },
            listDirectory: { $0 == "/Users/Jane Smith/.nvm/versions/node" ? ["v22.3.0"] : [] })
        #expect(found == "/opt/homebrew/bin/claude")
    }
}
