import AppKit
import WebKit
import XCTest

/// A web view in a window that is never ordered front, so layout and
/// `getBoundingClientRect` work without taking the screen.
@MainActor
final class OffscreenWebView: NSObject, WKNavigationDelegate {
    let window: NSWindow
    let webView: WKWebView
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        self.window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: 800, height: 600),
            styleMask: .borderless, backing: .buffered, defer: false)
        self.webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        super.init()
        self.window.contentView = self.webView
        self.webView.navigationDelegate = self
    }

    func load(html: String, baseURL: URL? = URL(string: "http://fixture.test/")) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    func load(fixture name: String) async throws {
        let url = try XCTUnwrap(Bundle(for: OffscreenWebView.self).url(forResource: name, withExtension: "html"))
        await self.load(html: try String(contentsOf: url, encoding: .utf8))
    }

    static func expected(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle(for: OffscreenWebView.self).url(forResource: name, withExtension: "txt"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.continuation?.resume()
        self.continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.continuation?.resume()
        self.continuation = nil
    }
}
