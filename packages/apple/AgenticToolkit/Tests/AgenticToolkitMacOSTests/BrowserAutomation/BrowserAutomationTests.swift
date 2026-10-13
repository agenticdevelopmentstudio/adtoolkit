// swiftlint:disable line_length identifier_name
import XCTest
import WebKit
@testable import AgenticToolkitMacOS

@MainActor
final class BrowserAutomationTests: XCTestCase {

    private var pages: [OffscreenWebView] = []

    private func make(html: String) async -> (OffscreenWebView, BrowserAutomation) {
        let page = OffscreenWebView()
        await page.load(html: html)
        let automation = BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())
        page.automation = automation
        pages.append(page)   // the window and delegate must outlive the test body
        return (page, automation)
    }

    func testFillOnControlledInputFiresInputAndChange() async throws {
        let (_, a) = await make(html: """
            <input id="q" value=""><span id="out"></span>
            <script>
            q.addEventListener('input', e => out.textContent = 'input:' + e.target.value);
            q.addEventListener('change', e => out.textContent += ' change');
            </script>
            """)
        let snap = try await a.snapshot(.init())
        let delta = try await a.fill(ref: "e1", generation: snap.generation, value: "hello")
        let text = try await a.text(scope: nil)
        XCTAssertEqual(text, "input:hello change")
        XCTAssertTrue(delta.changed)
    }

    func testTypeAppendsPerCharacterAndSubmitPressesEnter() async throws {
        let (_, a) = await make(html: """
            <input id="q" value="ab"><span id="out"></span>
            <script>
            q.addEventListener('keydown', e => { if (e.key === 'Enter') out.textContent = 'enter:' + q.value; });
            </script>
            """)
        let snap = try await a.snapshot(.init())
        _ = try await a.type(ref: "e1", generation: snap.generation, text: "cd", submit: true)
        let shown = try await a.text(scope: nil)
        XCTAssertEqual(shown, "enter:abcd")
    }

    func testClickLinkNavigatesAndDeltaReportsIt() async throws {
        let (_, a) = await make(html: "<a href=\"#second\" onclick=\"document.title='Second'\">Go</a>")
        let snap = try await a.snapshot(.init())
        let delta = try await a.click(ref: "e1", generation: snap.generation, native: false)
        XCTAssertEqual(delta.title, "Second")
        XCTAssertTrue(delta.url?.hasSuffix("#second") ?? false)
    }

    func testStaleGenerationIsRefused() async throws {
        let (_, a) = await make(html: "<button>One</button>")
        let snap = try await a.snapshot(.init())
        _ = try await a.snapshot(.init())
        do {
            _ = try await a.click(ref: "e1", generation: snap.generation, native: false)
            XCTFail("expected stale")
        } catch let error as BrowserAutomationError {
            XCTAssertEqual(error, .staleRef)
        }
    }

    func testClickOnRemovedElementIsStale() async throws {
        let (_, a) = await make(html: "<button id=\"b\">One</button>")
        let snap = try await a.snapshot(.init())
        _ = try await a.evaluate("document.getElementById('b').remove()")
        do {
            _ = try await a.click(ref: "e1", generation: snap.generation, native: false)
            XCTFail("expected stale")
        } catch let error as BrowserAutomationError {
            XCTAssertEqual(error, .staleRef)
        }
    }

    func testSnapshotOfBlankPageIsEmptyDocument() async throws {
        let page = OffscreenWebView()
        await page.load(html: "", baseURL: nil)
        let a = BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())
        let snap = try await a.snapshot(.init())
        XCTAssertEqual(snap.text, "- document:\n")
    }

    func testSelectByValueAndByLabel() async throws {
        let (_, a) = await make(html: """
            <select id="s"><option value="a">Alpha</option><option value="b">Beta</option></select>
            <span id="out"></span><script>s.addEventListener('change', () => out.textContent = s.value)</script>
            """)
        let snap = try await a.snapshot(.init())
        _ = try await a.select(ref: "e1", generation: snap.generation, value: "Beta")
        let shown = try await a.text(scope: "#out")
        XCTAssertEqual(shown, "b")
        _ = try await a.select(ref: "e1", generation: snap.generation, value: "a")
        let shownAgain = try await a.text(scope: "#out")
        XCTAssertEqual(shownAgain, "a")
    }

    func testHoverFiresMouseEvents() async throws {
        let (_, a) = await make(html: """
            <button id="b">Hi</button><span id="out"></span>
            <script>b.addEventListener('mouseover', () => out.textContent = 'over')</script>
            """)
        let snap = try await a.snapshot(.init())
        _ = try await a.hover(ref: "e1", generation: snap.generation)
        let shown = try await a.text(scope: "#out")
        XCTAssertEqual(shown, "over")
    }

    func testPressKeyWithModifierReachesTheFocusedElement() async throws {
        let (_, a) = await make(html: """
            <input id="q"><span id="out"></span>
            <script>q.focus(); q.addEventListener('keydown', e => out.textContent = (e.metaKey ? 'meta+' : '') + e.key)</script>
            """)
        _ = try await a.pressKey("Meta+a")
        let shown = try await a.text(scope: nil)
        XCTAssertEqual(shown, "meta+a")
    }

    func testWaitForTextResolvesWhenTextAppears() async throws {
        let (_, a) = await make(html: "<div id=\"d\"></div><script>setTimeout(() => d.textContent = 'ready', 200)</script>")
        let result = try await a.wait(for: .text("ready"), timeout: 5)
        XCTAssertTrue(result.satisfied)
    }

    func testWaitForTextTimesOutWithASentence() async throws {
        let (_, a) = await make(html: "<div>nothing</div>")
        do {
            _ = try await a.wait(for: .text("never"), timeout: 0.3)
            XCTFail("expected timeout")
        } catch let error as BrowserAutomationError {
            XCTAssertEqual(error.description, "timed out waiting for text \"never\"")
        }
    }

    func testWaitForIdleResolvesAfterMutationsStop() async throws {
        let (_, a) = await make(html: "<div id=\"d\"></div><script>let n=0; const t=setInterval(()=>{ d.textContent = ++n; if (n===3) clearInterval(t); }, 50)</script>")
        let result = try await a.wait(for: .idle, timeout: 5)
        XCTAssertTrue(result.satisfied)
    }

    func testAlertIsDismissedAndReported() async throws {
        let (_, a) = await make(html: "<button onclick=\"alert('hi')\">A</button>")
        let snap = try await a.snapshot(.init())
        let delta = try await a.click(ref: "e1", generation: snap.generation, native: false)
        XCTAssertEqual(delta.dialog?.kind, .alert)
        XCTAssertEqual(delta.dialog?.message, "hi")
    }

    func testDeltaIsFocusedLandmarkAfterDomChange() async throws {
        let (_, a) = await make(html: """
            <form id="f"><input id="q"><span id="out"></span></form>
            <script>q.addEventListener('input', () => out.textContent = 'typed')</script>
            """)
        let snap = try await a.snapshot(.init())
        let delta = try await a.fill(ref: "e2", generation: snap.generation, value: "x")
        XCTAssertTrue(delta.changed)
        XCTAssertTrue(delta.focused?.contains("- form") ?? false)
        XCTAssertTrue(delta.focused?.contains("typed") ?? false)
    }

    func testScreenshotIsPNGAndCapped() async throws {
        let (_, a) = await make(html: "<div style=\"width:3000px;height:10px;background:red\"></div>")
        let png = try await a.screenshot(ref: nil, generation: nil)
        XCTAssertEqual(Array(png.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
        let image = try XCTUnwrap(NSBitmapImageRep(data: png))
        XCTAssertLessThanOrEqual(max(image.pixelsWide, image.pixelsHigh), 1568)
    }

    func testCapExceedingSnapshotIsResampledToPixelCap() async throws {
        let (page, a) = await make(html: "<div style=\"width:100px;height:100px;background:red\"></div>")
        page.window.setContentSize(NSSize(width: 2400, height: 1000))
        page.webView.frame = NSRect(x: 0, y: 0, width: 2400, height: 1000)
        let png = try await a.screenshot(ref: nil, generation: nil)
        let image = try XCTUnwrap(NSBitmapImageRep(data: png))
        XCTAssertEqual(max(image.pixelsWide, image.pixelsHigh), 1568)
    }

    func testStaleRefFromPreviousDocumentIsRefused() async throws {
        let (page, a) = await make(html: "<button>One</button>")
        let first = try await a.snapshot(.init())
        await page.load(html: "<button>Two</button>")
        _ = try await a.snapshot(.init())
        do {
            _ = try await a.click(ref: "e1", generation: first.generation, native: false)
            XCTFail("expected stale")
        } catch let error as BrowserAutomationError {
            XCTAssertEqual(error, .staleRef)
        }
    }

    func testConsoleLogCapturesLevelsAndErrors() async throws {
        let console = BrowserConsoleLog()
        let page = OffscreenWebView()
        page.webView.configuration.userContentController.addUserScript(console.userScript)
        page.webView.configuration.userContentController.add(console, name: BrowserConsoleLog.handlerName)
        await page.load(html: "<script>console.warn('careful'); console.log('a', {b: 1}); undefinedFn();</script>")
        let a = BrowserAutomation(webView: page.webView, console: console)
        _ = try await a.wait(for: .idle, timeout: 2)
        let all = console.messages(level: nil)
        XCTAssertTrue(all.contains { $0.level == "warn" && $0.text == "careful" })
        XCTAssertTrue(all.contains { $0.level == "log" && $0.text == "a {\"b\":1}" })
        XCTAssertTrue(all.contains { $0.level == "error" && $0.text.contains("undefinedFn") })
        XCTAssertEqual(console.messages(level: "warn").count, 1)
    }

    func testDriveTogglesActionInFlight() async throws {
        let (_, a) = await make(html: "<p>x</p>")
        var seen: [Bool] = []
        a.onDriveStateChange = { seen.append($0) }
        _ = try await a.drive { try await a.text(scope: nil) }
        XCTAssertEqual(seen, [true, false])
        XCTAssertFalse(a.isActionInFlight)
    }

    func testNativeClickReachesThePage() async throws {
        let (_, a) = await make(html: """
            <button id="b" style="position:absolute;left:10px;top:10px;width:100px;height:40px">Hi</button>
            <span id="out"></span><script>b.addEventListener('click', () => out.textContent = 'clicked')</script>
            """)
        let snap = try await a.snapshot(.init())
        _ = try await a.click(ref: "e1", generation: snap.generation, native: true)
        _ = try await a.wait(for: .text("clicked"), timeout: 3)
    }
}
// swiftlint:enable line_length identifier_name
