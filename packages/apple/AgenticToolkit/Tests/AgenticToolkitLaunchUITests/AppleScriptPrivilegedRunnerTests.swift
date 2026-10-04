import Testing
@testable import AgenticToolkitLaunchUI

@Suite struct AppleScriptPrivilegedRunnerTests {
    @Test func quotesEveryWord() {
        let argv = ["/bin/ln", "-sf", "/Applications/My App.app/steno", "/usr/local/bin/steno"]
        let expected = #"do shell script "'/bin/ln' '-sf' '/Applications/My App.app/steno' "#
            + #"'/usr/local/bin/steno'" with administrator privileges"#
        #expect(AppleScriptPrivilegedRunner.script(for: argv) == expected)
    }

    @Test func escapesSingleQuotesAndAppleScriptSpecials() {
        let script = AppleScriptPrivilegedRunner.script(for: ["/bin/echo", #"it's "x" \ y"#])
        #expect(script == #"do shell script "'/bin/echo' 'it'\\''s \"x\" \\ y'" with administrator privileges"#)
    }

    @Test func newlineStaysInsideSingleQuotes() {
        let script = AppleScriptPrivilegedRunner.script(for: ["/bin/echo", "a\nb"])
        #expect(script == "do shell script \"'/bin/echo' 'a\nb'\" with administrator privileges")
    }

    @Test func loneSingleQuoteArgument() {
        let script = AppleScriptPrivilegedRunner.script(for: ["'"])
        #expect(script == #"do shell script "''\\'''" with administrator privileges"#)
    }

    @Test func substitutionsStayInert() {
        let script = AppleScriptPrivilegedRunner.script(for: ["/bin/echo", "$(rm -rf /)", "`id`"])
        #expect(script == #"do shell script "'/bin/echo' '$(rm -rf /)' '`id`'" with administrator privileges"#)
    }

    @Test @MainActor func emptyArgvThrowsBeforeAnyPrompt() async {
        await #expect(throws: AppleScriptPrivilegedRunner.Failure.failed(code: -1, message: "No command given.")) {
            try await AppleScriptPrivilegedRunner().run([])
        }
    }
}
