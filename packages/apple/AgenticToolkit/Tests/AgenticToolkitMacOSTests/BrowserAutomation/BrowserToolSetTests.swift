// swiftlint:disable line_length force_try force_cast
import XCTest
import WebKit
@testable import AgenticToolkitMacOS
@testable import AgenticToolkitCore

@MainActor
final class FakeBrowserDirectory: BrowserPaneDirectory {
    var panes: [BrowserPaneHandle] = []
    var beside: [String: String] = [:]      // caller pane id -> browser pane id
    var lastUsed: String?
    var opened: [String?] = []
    var openFails = false
    let pages: [String: OffscreenWebView]

    init(pages: [String: OffscreenWebView]) { self.pages = pages }

    func browserPanes() -> [BrowserPaneHandle] { panes }
    func browserPane(id: String) -> BrowserPaneHandle? { panes.first { $0.id == id } }
    func browserPane(besidePane paneID: String) -> BrowserPaneHandle? { beside[paneID].flatMap(browserPane(id:)) }
    func lastUsedBrowserPane() -> BrowserPaneHandle? { lastUsed.flatMap(browserPane(id:)) }
    func openBrowserPane(besidePane paneID: String?) throws -> BrowserPaneHandle {
        opened.append(paneID)
        if openFails { throw BrowserAutomationError.openRefused }
        let page = OffscreenWebView()
        let handle = BrowserPaneHandle(id: "new-\(panes.count)", project: "proj", tab: "Tab", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()))
        panes.append(handle)
        return handle
    }
}

@MainActor
final class BrowserToolSetTests: XCTestCase {

    private var store: UserSettings!
    private var directory: FakeBrowserDirectory!
    private var tools: BrowserToolSet!
    private var pages: [String: OffscreenWebView] = [:]

    override func setUp() async throws {
        store = UserSettings(with: InMemorySettingsStorageProvider(), secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        pages = ["A": OffscreenWebView(), "B": OffscreenWebView()]
        await pages["A"]!.load(html: "<title>Alpha</title><button>One</button>")
        await pages["B"]!.load(html: "<title>Beta</title><a href=\"/x\">Two</a>")
        directory = FakeBrowserDirectory(pages: pages)
        for (id, page) in pages.sorted(by: { $0.key < $1.key }) {
            directory.panes.append(BrowserPaneHandle(id: id, project: "proj", tab: "Tab \(id)", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())))
        }
        tools = BrowserToolSet(directory: directory, settings: store)
    }

    private func call(_ name: String, _ args: [String: Any] = [:], caller: String? = nil) async -> (content: String, isError: Bool) {
        let data = try! JSONSerialization.data(withJSONObject: args)
        return await tools.callTool(name: name, argumentsJSON: data, caller: caller)
    }

    func testAdvertisesTwentyToolsWithObjectSchemas() async {
        let defs = await tools.toolDefinitions()
        XCTAssertEqual(defs.count, 20)
        XCTAssertEqual(Set(defs.map(\.name)), Set(BrowserToolSet.toolNames))
        for def in defs {
            let schema = try! JSONSerialization.jsonObject(with: def.parametersJSONSchema) as! [String: Any]
            XCTAssertEqual(schema["type"] as? String, "object", def.name)
            XCTAssertFalse(def.description.isEmpty, def.name)
        }
    }

    func testListNamesEveryPaneAndTheDefault() async {
        directory.lastUsed = "B"
        let reply = await call("browser_list")
        XCTAssertFalse(reply.isError)
        let rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["id"] as? String }, ["A", "B"])
        XCTAssertEqual(rows.map { $0["title"] as? String }, ["Alpha", "Beta"])
        XCTAssertEqual(rows.map { $0["is_default"] as? Bool }, [false, true])
    }

    func testDefaultPaneIsBesideCallerThenLastUsedThenFirst() async {
        directory.beside["term-1"] = "B"
        directory.lastUsed = "A"
        let beside = await call("browser_snapshot", caller: "term-1")
        XCTAssertTrue(beside.content.contains("Two"), beside.content)
        let lastUsed = await call("browser_snapshot", caller: "term-9")
        XCTAssertTrue(lastUsed.content.contains("One"), lastUsed.content)
        directory.lastUsed = nil
        let first = await call("browser_snapshot")
        XCTAssertTrue(first.content.contains("One"), first.content)
    }

    func testExplicitPaneIDWins() async {
        directory.lastUsed = "A"
        let reply = await call("browser_snapshot", ["pane_id": "B"])
        XCTAssertTrue(reply.content.contains("Two"), reply.content)
    }

    func testClosedPaneIsASentence() async {
        let reply = await call("browser_snapshot", ["pane_id": "gone"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "pane gone was closed; call browser_list")
    }

    func testNoPaneIsASentence() async {
        directory.panes.removeAll()
        let reply = await call("browser_snapshot")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "no browser pane is open; call browser_open")
    }

    func testOpenAsksTheDirectoryBesideTheCaller() async {
        let reply = await call("browser_open", ["url": "about:blank"], caller: "term-1")
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertEqual(directory.opened, ["term-1"])
        XCTAssertTrue(reply.content.contains("new-2"))
    }

    /// The URL is optional: with none given the pane opens on the Home Page
    /// setting, and with that blank (as it is here) on a blank page.
    func testOpenWithoutAURLOpensABlankPage() async throws {
        let reply = await call("browser_open", caller: "term-1")
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.hasPrefix("opened pane new-2"), reply.content)
        XCTAssertEqual(directory.panes.last?.automation.currentURL, "about:blank")
        let open = try XCTUnwrap(BrowserToolSet.definitions.first { $0.name == "browser_open" })
        let schema = try XCTUnwrap(try JSONSerialization.jsonObject(with: open.parametersJSONSchema) as? [String: Any])
        XCTAssertFalse((schema["required"] as? [String] ?? []).contains("url"))
    }

    func testAFailedOpenIsTheSentence() async {
        directory.openFails = true
        let reply = await call("browser_open", ["url": "about:blank"], caller: "term-1")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "could not open a Browser pane beside that pane")
    }

    func testOpenRefusesNonHTTP() async {
        let reply = await call("browser_open", ["url": "file:///etc/passwd"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "only http and https URLs can be opened")
        XCTAssertTrue(directory.opened.isEmpty)
    }

    func testNavigateRefusesNonHTTP() async {
        let reply = await call("browser_navigate", ["url": "javascript:alert(1)"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "only http and https URLs can be opened")
    }

    func testFilePaneIsRefused() async {
        let page = OffscreenWebView()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("local-\(UUID().uuidString).html")
        try! "<p>local</p>".write(to: url, atomically: true, encoding: .utf8)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            page.webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { done.resume() }
        }
        directory.panes = [BrowserPaneHandle(id: "F", project: "p", tab: "t", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()))]
        let reply = await call("browser_snapshot")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "pane F shows a local file, which models may not drive")
    }

    /// A call queued behind another is checked again when it runs: the switch
    /// flipped off meanwhile refuses it.
    func testSwitchTurnedOffWhileQueuedRefusesTheQueuedCall() async throws {
        let automation = directory.panes[0].automation
        let store = self.store!
        let held = Task { @MainActor in
            try await automation.drive {
                try await Task.sleep(nanoseconds: 300_000_000)
                store.set(false, for: UserSettings.browserAutomationEnabled)
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        let reply = await call("browser_snapshot", ["pane_id": "A"])
        _ = try await held.value
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser automation is turned off in Settings")
    }

    /// A pane that once showed a local file, then a page: a back that lands
    /// on the file is refused, and nothing is read from it.
    func testBackOntoALocalFileIsRefused() async throws {
        let page = OffscreenWebView()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("local-\(UUID().uuidString).html")
        try "<p>local</p>".write(to: url, atomically: true, encoding: .utf8)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            page.webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { done.resume() }
        }
        await page.load(html: "<title>Web</title><p>web</p>")
        directory.panes = [BrowserPaneHandle(id: "F", project: "p", tab: "t", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()))]
        let back = await call("browser_back")
        XCTAssertTrue(back.isError)
        XCTAssertEqual(back.content, "the pane shows a local file, which models may not drive")
        let text = await call("browser_text")
        XCTAssertTrue(text.isError)
        XCTAssertEqual(text.content, "pane F shows a local file, which models may not drive")
    }

    func testAutomationOffLeavesOnlyList() async {
        store.set(false, for: UserSettings.browserAutomationEnabled)
        let list = await call("browser_list")
        XCTAssertFalse(list.isError)
        let snap = await call("browser_snapshot")
        XCTAssertTrue(snap.isError)
        XCTAssertEqual(snap.content, "browser automation is turned off in Settings")
    }

    func testEvaluateIsOffByDefaultAndOnWhenEnabled() async {
        let off = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertTrue(off.isError)
        XCTAssertEqual(off.content, "browser_evaluate is turned off in Settings")
        store.set(true, for: UserSettings.browserAutomationEvaluate)
        let enabled = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertFalse(enabled.isError)
        XCTAssertEqual(enabled.content, "2")
    }

    func testMalformedArgumentsAreASentence() async {
        let reply = await tools.callTool(name: "browser_click", argumentsJSON: Data("{not json".utf8), caller: nil)
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click arguments are not valid JSON")
    }

    func testMissingRefIsASentence() async {
        let reply = await call("browser_click", ["generation": 1])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click needs ref")
    }

    func testUnknownToolIsASentence() async {
        let reply = await call("browser_fly")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "unknown tool browser_fly")
    }

    func testClickAfterSnapshotReturnsADelta() async {
        let snap = await call("browser_snapshot", ["pane_id": "A"])
        let gen = Int(snap.content.components(separatedBy: "generation: ").last!.components(separatedBy: "\n").first!)!
        let reply = await call("browser_click", ["pane_id": "A", "ref": "e1", "generation": gen])
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.contains("no visible change"))
    }

    func testStaleRefIsTheSentence() async {
        _ = await call("browser_snapshot", ["pane_id": "A"])
        let reply = await call("browser_click", ["pane_id": "A", "ref": "e1", "generation": 0])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "stale ref; take a new snapshot")
    }

    func testNonIntegerGenerationIsASentence() async {
        let reply = await tools.callTool(name: "browser_click", argumentsJSON: Data("{\"ref\":\"e1\",\"generation\":1e30}".utf8), caller: nil)
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click needs generation")
    }

    func testScreenshotRefWithoutGenerationIsASentence() async {
        let reply = await call("browser_screenshot", ["pane_id": "A", "ref": "e1"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_screenshot needs generation")
    }

    func testEmptyPaneIDMeansTheDefaultPane() async {
        directory.lastUsed = "B"
        let reply = await call("browser_snapshot", ["pane_id": ""])
        XCTAssertTrue(reply.content.contains("Two"), reply.content)
    }

    func testEvaluateOffSaysSoEvenWithNoPane() async {
        directory.panes.removeAll()
        let reply = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_evaluate is turned off in Settings")
    }

    func testScreenshotReturnsAnImageDataURL() async {
        pages["A"]!.orderInOffscreen()
        let reply = await call("browser_screenshot", ["pane_id": "A"])
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.hasPrefix("data:image/png;base64,"))
    }

    func testFindAndTextAndWait() async {
        let find = await call("browser_find", ["pane_id": "B", "text": "two"])
        XCTAssertTrue(find.content.contains("e1"), find.content)
        let text = await call("browser_text", ["pane_id": "B"])
        XCTAssertEqual(text.content.trimmingCharacters(in: .whitespacesAndNewlines), "Two")
        let wait = await call("browser_wait_for", ["pane_id": "B", "text": "Two", "timeout": 1])
        XCTAssertFalse(wait.isError, wait.content)
        let timeout = await call("browser_wait_for", ["pane_id": "B", "text": "never", "timeout": 0.2])
        XCTAssertTrue(timeout.isError)
        XCTAssertEqual(timeout.content, "timed out waiting for text \"never\"")
    }
}
// swiftlint:enable line_length force_try force_cast
