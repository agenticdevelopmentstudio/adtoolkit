import XCTest
import WebKit
@testable import AgenticToolkitMacOS

@MainActor
final class BrowserSnapshotTests: XCTestCase {

    private func snapshot(
        _ page: OffscreenWebView, options: BrowserSnapshotOptions = .init()
    ) async throws -> BrowserSnapshot {
        try await BrowserSnapshotRuntime.install(in: page.webView)
        let raw = try await page.webView.callAsyncJavaScript(
            "return window.__adkitchen.snapshot(opts)",
            arguments: ["opts": options.jsArguments], in: nil, contentWorld: .page)
        let data = try JSONSerialization.data(withJSONObject: raw as Any)
        let payload = try JSONDecoder().decode(BrowserSnapshotPayload.self, from: data)
        return BrowserSnapshot(payload: payload, includeURLs: options.includeURLs)
    }

    func testFormFixtureRendersLikePlaywright() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, try OffscreenWebView.expected("form"))
        XCTAssertEqual(snap.title, "Sign in")
        XCTAssertGreaterThan(snap.generation, 0)
    }

    func testLandmarksFixtureSkipsHiddenAndCollapsesGenerics() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, try OffscreenWebView.expected("landmarks"))
    }

    func testRefsRestartEverySnapshotAndGenerationAdvances() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let first = try await snapshot(page)
        let second = try await snapshot(page)
        XCTAssertEqual(second.generation, first.generation + 1)
        XCTAssertTrue(second.text.contains("[ref=e1]"))
    }

    func testInteractiveOnlyKeepsRefsAndDropsText() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        var options = BrowserSnapshotOptions()
        options.interactiveOnly = true
        let snap = try await snapshot(page, options: options)
        XCTAssertFalse(snap.text.contains("- text:"))
        XCTAssertTrue(snap.text.contains("- link \"Forgot password?\""))
        XCTAssertFalse(snap.text.contains("- heading"))
    }

    func testIncludeURLsAddsUrlAttribute() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        var options = BrowserSnapshotOptions()
        options.includeURLs = true
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.contains("- link \"Forgot password?\" [ref=e11] [url=http://fixture.test/reset]"))
    }

    func testScopeByRefSnapshotsOnlyThatSubtree() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        _ = try await snapshot(page)
        var options = BrowserSnapshotOptions()
        options.scope = "e3"
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.hasPrefix("- navigation [ref=e1]:"))
        XCTAssertFalse(snap.text.contains("contentinfo"))
    }

    func testDepthLimitsTheTree() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        var options = BrowserSnapshotOptions()
        options.depth = 2
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.contains("- navigation [ref=e3]"))
        XCTAssertFalse(snap.text.contains("- list "))
    }

    func testLongNamesAreCut() async throws {
        let page = OffscreenWebView()
        let long = String(repeating: "x", count: 120)
        await page.load(html: "<button>\(long)</button>")
        let snap = try await snapshot(page)
        XCTAssertTrue(snap.text.contains("\"" + String(repeating: "x", count: 100) + "…\""))
    }

    func testEmptyDocumentRendersRootWithColon() async throws {
        let page = OffscreenWebView()
        await page.load(html: "", baseURL: URL(string: "about:blank"))
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, "- document:\n")
    }

    func testFindReturnsMatchingRefs() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        _ = try await snapshot(page)
        let raw = try await page.webView.callAsyncJavaScript(
            "return window.__adkitchen.find(text)", arguments: ["text": "forgot"], in: nil, contentWorld: .page)
        let matches = try XCTUnwrap(raw as? [[String: Any]])
        XCTAssertEqual(matches.map { $0["ref"] as? String }, ["e11"])
        XCTAssertEqual(matches.first?["role"] as? String, "link")
    }

    func testTextReturnsInnerTextOfMain() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        try await BrowserSnapshotRuntime.install(in: page.webView)
        let raw = try await page.webView.callAsyncJavaScript(
            "return window.__adkitchen.text(scope)", arguments: ["scope": NSNull()], in: nil, contentWorld: .page)
        let text = try XCTUnwrap(raw as? String)
        XCTAssertTrue(text.hasPrefix("Sign in"))
        XCTAssertTrue(text.contains("Forgot password?"))
    }
}
