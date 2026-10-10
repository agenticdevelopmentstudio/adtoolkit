import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("TextSubstitutionFilter")
struct TextSubstitutionFilterTests {

    private let filter = TextSubstitutionFilter(parsing: "bobby mcfarin = mike fullerton")

    @Test("revealing replaces the alias with the real text")
    func reveals() {
        #expect(filter.revealing("echo bobby mcfarin") == "echo mike fullerton")
    }

    @Test("concealing replaces the real text with the alias, whatever its case")
    func concealsCaseInsensitively() {
        #expect(filter.concealing("Hello Mike Fullerton!") == "Hello bobby mcfarin!")
        #expect(filter.concealing("MIKE FULLERTON") == "bobby mcfarin")
    }

    @Test("a replacement is never rewritten by another pair")
    func singlePass() {
        let chain = TextSubstitutionFilter(parsing: "a = b; b = c")
        #expect(chain.revealing("a b") == "b c")
    }

    @Test("the longest match wins at each position")
    func longestFirst() {
        let both = TextSubstitutionFilter(parsing: "bob = mike\nbobby mcfarin = mike fullerton")
        #expect(both.concealing("mike fullerton and mike") == "bobby mcfarin and bob")
    }

    @Test("parsing skips half-written entries and empty sides")
    func parsingIsForgiving() {
        let parsed = TextSubstitutionFilter(parsing: "x = y; nonsense; = z; w = ;")
        #expect(parsed.pairs == [.init(alias: "x", real: "y")])
    }

    @Test("serialized reads back as the same filter")
    func roundTrips() {
        let both = TextSubstitutionFilter(parsing: "a = b\nc = d")
        #expect(TextSubstitutionFilter(parsing: both.serialized) == both)
    }

    @Test("with no pairs, text passes through unchanged")
    func identity() {
        #expect(TextSubstitutionFilter.identity.concealing("mike") == "mike")
    }
}
