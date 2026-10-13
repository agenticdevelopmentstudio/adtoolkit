import Foundation
import WebKit

public struct BrowserConsoleMessage: Sendable, Equatable {
    public var level: String
    public var text: String
    public var timestamp: Date
}

/// The last 200 console messages and uncaught errors of a web view.
/// Install `userScript` and `self` (as the handler named `handlerName`) on the
/// configuration the web view is created with; clear it on each navigation.
@MainActor
public final class BrowserConsoleLog: NSObject, WKScriptMessageHandler {
    public static let handlerName = "adkitchenConsole"
    public static let capacity = 200

    private var buffer: [BrowserConsoleMessage] = []

    public func messages(level: String?) -> [BrowserConsoleMessage] {
        guard let level else { return buffer }
        return buffer.filter { $0.level == level }
    }

    public func clear() { buffer.removeAll() }

    public func record(_ message: BrowserConsoleMessage) {
        buffer.append(message)
        if buffer.count > Self.capacity { buffer.removeFirst(buffer.count - Self.capacity) }
    }

    public var userScript: WKUserScript {
        WKUserScript(source: Self.script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    public func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let text = body["text"] as? String else { return }
        record(BrowserConsoleMessage(level: level, text: text, timestamp: Date()))
    }

    static let script = """
    (function () {
      if (window.__adkitchenConsoleInstalled) { return; }
      window.__adkitchenConsoleInstalled = true;
      const post = (level, text) => {
        try { window.webkit.messageHandlers.\(handlerName).postMessage({ level: level, text: text }); } catch (e) {}
      };
      const render = (args) => Array.from(args).map((a) => {
        if (typeof a === 'string') { return a; }
        try { return JSON.stringify(a); } catch (e) { return String(a); }
      }).join(' ');
      for (const level of ['log', 'info', 'warn', 'error', 'debug']) {
        const original = console[level];
        console[level] = function () {
          post(level, render(arguments));
          if (original) { original.apply(console, arguments); }
        };
      }
      window.addEventListener('error', (e) => post('error',
        (e.message || 'error') + (e.filename ? ' (' + e.filename + ':' + e.lineno + ')' : '')));
      window.addEventListener('unhandledrejection', (e) => post('error',
        'unhandled rejection: ' + (e.reason && e.reason.message ? e.reason.message : String(e.reason))));
    })();
    """
}
