import AppKit
import Testing
@testable import AgenticToolkitLaunchUI

@Suite struct AppleScriptPrivilegedRunnerTests {
    @Test func quotesEveryWord() {
        let argv = ["/bin/ln", "-sf", "/Applications/My App.app/steno", "/usr/local/bin/steno"]
        #expect(AppleScriptPrivilegedRunner.shellCommand(for: argv)
            == "'/bin/ln' '-sf' '/Applications/My App.app/steno' '/usr/local/bin/steno'")
    }

    @Test func escapesSingleQuotesOnly() {
        // The command is an AppleScript parameter, not source: `"` and `\`
        // pass through untouched.
        let command = AppleScriptPrivilegedRunner.shellCommand(for: ["/bin/echo", #"it's "x" \ y"#])
        #expect(command == #"'/bin/echo' 'it'\''s "x" \ y'"#)
    }

    @Test func newlineStaysInsideSingleQuotes() {
        #expect(AppleScriptPrivilegedRunner.shellCommand(for: ["/bin/echo", "a\nb"]) == "'/bin/echo' 'a\nb'")
    }

    @Test func loneSingleQuoteArgument() {
        #expect(AppleScriptPrivilegedRunner.shellCommand(for: ["'"]) == #"''\'''"#)
    }

    @Test func substitutionsStayInert() {
        let command = AppleScriptPrivilegedRunner.shellCommand(for: ["/bin/echo", "$(rm -rf /)", "`id`"])
        #expect(command == "'/bin/echo' '$(rm -rf /)' '`id`'")
    }

    @Test func quoteWithCombiningMarkIsStillEscaped() {
        #expect(AppleScriptPrivilegedRunner.shellCommand(for: ["a'\u{301}b"]) == "'a'\\''\u{301}b'")
    }

    @Test @MainActor func handlerCompiles() {
        let script = NSAppleScript(source: AppleScriptPrivilegedRunner.handlerSource)
        var error: NSDictionary?
        #expect(script?.compileAndReturnError(&error) == true)
        #expect(error == nil)
    }

    /// The handler mechanism, proven with a harmless twin that echoes its
    /// parameter instead of elevating: the event reaches the handler by name
    /// and delivers the command intact, quotes and all.
    @Test @MainActor func handlerEventDeliversTheCommand() throws {
        let name = AppleScriptPrivilegedRunner.handlerName
        let echo = NSAppleScript(source: "on \(name)(command)\nreturn command\nend \(name)")
        let script = try #require(echo)
        let command = AppleScriptPrivilegedRunner.shellCommand(for: ["/bin/echo", #"it's "x" \ y"#])
        var error: NSDictionary?
        let result = script.executeAppleEvent(
            AppleScriptPrivilegedRunner.handlerEvent(command: command), error: &error)
        #expect(error == nil)
        #expect(result.stringValue == command)
    }

    @Test @MainActor func nulArgumentThrowsBeforeAnyPrompt() async {
        let failure = AppleScriptPrivilegedRunner.Failure.failed(
            code: -1, message: "A command argument contains a NUL character.")
        await #expect(throws: failure) {
            try await AppleScriptPrivilegedRunner().run(["/bin/echo", "a\u{0}b"])
        }
    }

    @Test @MainActor func emptyArgvThrowsBeforeAnyPrompt() async {
        await #expect(throws: AppleScriptPrivilegedRunner.Failure.failed(code: -1, message: "No command given.")) {
            try await AppleScriptPrivilegedRunner().run([])
        }
    }
}
