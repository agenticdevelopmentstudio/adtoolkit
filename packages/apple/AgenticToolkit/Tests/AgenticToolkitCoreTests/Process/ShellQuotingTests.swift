import Foundation
import Testing
@testable import AgenticToolkitCore

struct ShellQuotingTests {

    @Test func emptyWordIsQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("") == "''")
    }

    @Test func plainWordIsUnchanged() {
        #expect(ShellQuoting.quoteIfNeeded("/usr/local/bin/steno-1.2") == "/usr/local/bin/steno-1.2")
    }

    @Test func singleQuoteIsEscapedLikeShlex() {
        #expect(ShellQuoting.quoteIfNeeded("it's") == "'it'\"'\"'s'")
    }

    @Test func singleQuoteBeforeCombiningMarkIsEscaped() {
        #expect(ShellQuoting.quote("a'\u{301}b") == "'a'\"'\"'\u{301}b'")
    }

    @Test func spacesAreQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("a b") == "'a b'")
    }

    @Test func nonASCIILetterIsQuoted() {
        #expect(ShellQuoting.quoteIfNeeded("caf\u{e9}") == "'caf\u{e9}'")
    }

    @Test func quoteAlwaysQuotes() {
        #expect(ShellQuoting.quote("plain") == "'plain'")
    }

    @Test func commandLineQuotesOnlyWordsThatNeedIt() {
        #expect(ShellQuoting.commandLine(["ls", "-la", "my dir"]) == "ls -la 'my dir'")
    }
}
