import Foundation
import WebKit

/// Options for `browser_snapshot`, mirrored to the JS runtime.
public struct BrowserSnapshotOptions: Sendable {
    public var interactiveOnly = false
    public var depth: Int?
    public var scope: String?
    public var includeURLs = false
    public var delta = false
    public init() {}

    /// What the JS `snapshot(opts)` call receives.
    var jsArguments: [String: Any] {
        var out: [String: Any] = ["interactiveOnly": interactiveOnly]
        if let depth { out["depth"] = depth }
        if let scope { out["scope"] = scope }
        return out
    }
}

/// One node of the JSON tree the runtime returns.
public struct BrowserSnapshotNode: Decodable, Sendable {
    public var role: String
    public var name: String?
    public var ref: String?
    public var states: [String]
    public var level: Int?
    public var url: String?
    public var value: String?
    public var text: String?
    public var children: [BrowserSnapshotNode]

    private enum CodingKeys: String, CodingKey { case role, name, ref, states, level, url, value, text, children }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        ref = try container.decodeIfPresent(String.self, forKey: .ref)
        states = try container.decodeIfPresent([String].self, forKey: .states) ?? []
        // A level the page misreports (a fraction, a word) is dropped, not fatal:
        // one bad heading must not cost the whole snapshot.
        if let raw = try? container.decodeIfPresent(Double.self, forKey: .level) { level = Int(exactly: raw) }
        url = try container.decodeIfPresent(String.self, forKey: .url)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        children = try container.decodeIfPresent([BrowserSnapshotNode].self, forKey: .children) ?? []
    }
}

/// The whole JSON answer of `snapshot(opts)`.
public struct BrowserSnapshotPayload: Decodable, Sendable {
    public var url: String
    public var title: String
    public var generation: Int
    public var root: BrowserSnapshotNode
}

/// A rendered snapshot: what a tool returns.
public struct BrowserSnapshot: Sendable {
    public var text: String
    public var url: String
    public var title: String
    public var generation: Int

    public init(payload: BrowserSnapshotPayload, includeURLs: Bool) {
        self.text = BrowserSnapshotRenderer.render(payload.root, includeURLs: includeURLs)
        self.url = payload.url
        self.title = payload.title
        self.generation = payload.generation
    }
}

/// Renders the tree in Playwright's `ariaSnapshot` text form.
public enum BrowserSnapshotRenderer {
    public static func render(_ root: BrowserSnapshotNode, includeURLs: Bool) -> String {
        var lines: [String] = []
        append(root, depth: 0, includeURLs: includeURLs, into: &lines)
        return lines.joined(separator: "\n") + "\n"
    }

    private static func append(_ node: BrowserSnapshotNode, depth: Int, includeURLs: Bool, into lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        if node.role == "text" {
            lines.append("\(indent)- text: \(node.text ?? "")")
            return
        }
        var line = "\(indent)- \(node.role)"
        if let name = node.name, !name.isEmpty { line += " \"\(name)\"" }
        if let ref = node.ref { line += " [ref=\(ref)]" }
        if let level = node.level { line += " [level=\(level)]" }
        for state in node.states { line += " [\(state)]" }
        if let value = node.value { line += " [value=\"\(value)\"]" }
        if includeURLs, let url = node.url { line += " [url=\(url)]" }
        if !node.children.isEmpty || (depth == 0 && node.role == "document") { line += ":" }
        lines.append(line)
        for child in node.children { append(child, depth: depth + 1, includeURLs: includeURLs, into: &lines) }
    }
}

/// Loads and installs `BrowserSnapshot.js` into a web view, in a content
/// world of its own.
///
/// The runtime sees the page's real DOM from any world, but only an isolated
/// world keeps its own state out of the page's reach: in the page world a
/// site's script could read the ref table, retarget a ref at another element,
/// or replace `window.__adkitchen` wholesale, and the model would then be
/// clicking what the page chose. Only `BrowserAutomation.evaluate` runs in the
/// page world, because reading the page's own JavaScript is its purpose.
public enum BrowserSnapshotRuntime {
    public static let version = 1

    /// The content world the runtime lives in. `WKContentWorld.world(name:)`
    /// returns the same world for the same name, so this needs no storage.
    @MainActor
    public static var world: WKContentWorld { .world(name: "adkitchen.automation") }

    public static var source: String {
        get throws {
            guard let url = Bundle(for: BrowserAutomationBundleAnchor.self)
                .url(forResource: "BrowserSnapshot", withExtension: "js") else {
                throw BrowserAutomationError.runtimeMissing
            }
            return try String(contentsOf: url, encoding: .utf8)
        }
    }

    /// Idempotent: the script returns early when the current version is present.
    @MainActor
    public static func install(in webView: WKWebView) async throws {
        _ = try await webView.evaluateJavaScript(try source, in: nil, contentWorld: world)
    }
}

/// A class in this framework for `Bundle(for:)`; enums cannot anchor a bundle lookup.
final class BrowserAutomationBundleAnchor {}

/// Every way automation can fail, each a sentence a model can act on.
public enum BrowserAutomationError: Error, CustomStringConvertible, Equatable, Sendable {
    case staleRef
    case unknownRef(String)
    case script(String)
    case timeout(String)
    case runtimeMissing
    case noWindow
    case notOnScreen
    case screenshotTimedOut
    case cspRefusesEvaluation
    case openRefused
    /// The page is a `file:` URL. Models never drive local files.
    case localFile

    public var description: String {
        switch self {
        case .staleRef: return "stale ref; take a new snapshot"
        case .unknownRef(let ref): return "unknown ref \(ref); take a new snapshot"
        case .script(let message): return "the page refused: \(message)"
        case .timeout(let what): return "timed out waiting for \(what)"
        case .runtimeMissing: return "the browser automation runtime is missing from the bundle"
        case .noWindow: return "the pane is not in a window"
        case .notOnScreen: return "the pane is not on screen"
        case .screenshotTimedOut: return "the screenshot timed out"
        case .cspRefusesEvaluation: return "the page's Content Security Policy refuses evaluation"
        case .openRefused: return "could not open a Browser pane beside that pane"
        case .localFile: return "the pane shows a local file, which models may not drive"
        }
    }
}
