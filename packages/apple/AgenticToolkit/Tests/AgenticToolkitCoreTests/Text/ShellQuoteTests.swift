import Foundation
import Testing
@testable import AgenticToolkitCore

struct ShellQuoteTests {

    @Test func emptyWordIsQuoted() {
        #expect(ShellQuote.word("") == "''")
    }

    @Test func plainWordIsUnchanged() {
        #expect(ShellQuote.word("/usr/local/bin/steno-1.2") == "/usr/local/bin/steno-1.2")
    }

    @Test func singleQuoteIsEscaped() {
        #expect(ShellQuote.word("it's") == "'it'\"'\"'s'")
    }

    @Test func spacesAreQuoted() {
        #expect(ShellQuote.word("a b") == "'a b'")
    }
}
