// swiftlint:disable line_length identifier_name
import AppKit
import WebKit

public struct BrowserDialog: Sendable, Equatable {
    public enum Kind: String, Sendable { case alert, confirm, prompt }
    public var kind: Kind
    public var message: String
}

/// What changed because of one action.
public struct BrowserActionDelta: Sendable {
    public var url: String?
    public var title: String?
    public var navigated = false
    public var pending = false
    public var changed = false
    public var focused: String?
    public var dialog: BrowserDialog?

    public func rendered() -> String {
        var lines: [String] = []
        if navigated {
            lines.append("navigated to \(url ?? "?") — \(title ?? "")")
        } else {
            if let url { lines.append("url: \(url)") }
            if let title { lines.append("title: \(title)") }
        }
        if pending { lines.append("a navigation is still in progress; call browser_wait_for load") }
        if let dialog { lines.append("dialog (\(dialog.kind.rawValue), dismissed): \(dialog.message)") }
        if let focused { lines.append(focused) }
        if lines.isEmpty { return changed ? "changed" : "no visible change" }
        return lines.joined(separator: "\n")
    }
}

public enum BrowserWaitCondition: Sendable, Equatable {
    case text(String)
    case ref(String, generation: Int)
    case url(String)
    case load
    case idle

    var description: String {
        switch self {
        case .text(let needle): return "text \"\(needle)\""
        case .ref(let ref, _): return "ref \(ref)"
        case .url(let fragment): return "url containing \"\(fragment)\""
        case .load: return "load"
        case .idle: return "idle"
        }
    }
}

public struct BrowserWaitResult: Sendable {
    public var satisfied: Bool
    public var url: String
    public var title: String
}

public struct BrowserFindMatch: Sendable, Equatable {
    public var ref: String
    public var role: String
    public var name: String
}

/// Drives one `WKWebView` on behalf of a model.
@MainActor
public final class BrowserAutomation: NSObject {
    public static let defaultTimeout: TimeInterval = 10
    public static let maximumTimeout: TimeInterval = 60
    public static let maximumScreenshotSide: CGFloat = 1568

    public let webView: WKWebView
    public let console: BrowserConsoleLog

    public private(set) var isActionInFlight = false
    public var onDriveStateChange: ((Bool) -> Void)?

    private var driveDepth = 0
    private var pendingDialog: BrowserDialog?
    private var loadObservation: NSKeyValueObservation?
    private var navigationsStarted = 0
    private var navigationsFinished = 0

    public init(webView: WKWebView, console: BrowserConsoleLog) {
        self.webView = webView
        self.console = console
        super.init()
        self.loadObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] _, change in
            Task { @MainActor in
                guard let self else { return }
                if change.newValue == true { self.navigationsStarted += 1 } else { self.navigationsFinished += 1 }
            }
        }
    }

    public var currentURL: String { webView.url?.absoluteString ?? "about:blank" }
    public var currentTitle: String { webView.title ?? "" }

    // MARK: Driving

    /// Every tool call runs inside this so the pane can show its badge and
    /// route dialogs here. Re-entrant.
    public func drive<T>(_ body: () async throws -> T) async rethrows -> T {
        driveDepth += 1
        if driveDepth == 1 { isActionInFlight = true; onDriveStateChange?(true) }
        defer {
            driveDepth -= 1
            if driveDepth == 0 { isActionInFlight = false; onDriveStateChange?(false) }
        }
        return try await body()
    }

    /// Called by the pane's `WKUIDelegate` while an action is in flight.
    public func dialogRaised(kind: BrowserDialog.Kind, message: String) {
        pendingDialog = BrowserDialog(kind: kind, message: message)
    }

    // MARK: Runtime calls

    private func call(_ function: String, _ ordered: KeyValuePairs<String, Any> = [:]) async throws -> Any? {
        try await BrowserSnapshotRuntime.install(in: webView)
        // Positional order matters to the JS functions, so keep the caller's order.
        let names = ordered.map(\.key)
        var arguments: [String: Any] = [:]
        for (key, value) in ordered { arguments[key] = value }
        let body = "return window.__adkitchen.\(function)(\(names.joined(separator: ", ")))"
        let raw: Any?
        do {
            raw = try await webView.callAsyncJavaScript(body, arguments: arguments, in: nil, contentWorld: .page)
        } catch {
            throw BrowserAutomationError.script(error.localizedDescription)
        }
        if let envelope = raw as? [String: Any], let error = envelope["error"] as? String {
            switch error {
            case "stale": throw BrowserAutomationError.staleRef
            case "unknown": throw BrowserAutomationError.unknownRef(arguments["ref"] as? String ?? "?")
            default: throw BrowserAutomationError.script(error.replacingOccurrences(of: "script: ", with: ""))
            }
        }
        if let envelope = raw as? [String: Any], envelope.keys.contains("ok") { return envelope["ok"] }
        return raw
    }

    // MARK: Reading

    public func snapshot(_ options: BrowserSnapshotOptions) async throws -> BrowserSnapshot {
        let raw = try await call("snapshot", ["opts": options.jsArguments])
        let data = try JSONSerialization.data(withJSONObject: raw as Any)
        let payload = try JSONDecoder().decode(BrowserSnapshotPayload.self, from: data)
        var snapshot = BrowserSnapshot(payload: payload, includeURLs: options.includeURLs)
        if options.delta, let previous = lastSnapshotLines {
            snapshot.text = Self.delta(from: previous, to: snapshot.text)
        }
        lastSnapshotLines = BrowserSnapshot(payload: payload, includeURLs: options.includeURLs).text
            .split(separator: "\n").map(String.init)
        return snapshot
    }

    private var lastSnapshotLines: [String]?

    static func delta(from previous: [String], to current: String) -> String {
        let now = current.split(separator: "\n").map(String.init)
        let strip: (String) -> String = { $0.replacingOccurrences(of: #" \[ref=e\d+\]"#, with: "", options: .regularExpression) }
        let before = Set(previous.map(strip))
        let after = Set(now.map(strip))
        let added = now.filter { !before.contains(strip($0)) }
        let removed = previous.filter { !after.contains(strip($0)) }
        if added.isEmpty && removed.isEmpty { return "no change since the last snapshot\n" }
        var out = ""
        if !added.isEmpty { out += "Added:\n" + added.joined(separator: "\n") + "\n" }
        if !removed.isEmpty { out += "Removed:\n" + removed.map(strip).joined(separator: "\n") + "\n" }
        return out
    }

    public func find(_ text: String) async throws -> [BrowserFindMatch] {
        let raw = try await call("find", ["text": text]) as? [[String: Any]] ?? []
        return raw.compactMap { match in
            guard let ref = match["ref"] as? String else { return nil }
            return BrowserFindMatch(ref: ref, role: match["role"] as? String ?? "generic",
                                    name: match["name"] as? String ?? "")
        }
    }

    public func text(scope: String?) async throws -> String {
        try await call("text", ["scope": scope ?? NSNull()]) as? String ?? ""
    }

    // MARK: Actions

    public func click(ref: String, generation: Int, native: Bool) async throws -> BrowserActionDelta {
        try await act {
            if native {
                let r = try await self.rect(ref: ref, generation: generation)
                try self.nativeClick(atPageX: r.midX, pageY: r.midY)
            } else {
                _ = try await self.call("click", ["ref": ref, "gen": generation])
            }
        }
    }

    public func type(ref: String, generation: Int, text: String, submit: Bool) async throws -> BrowserActionDelta {
        try await act { _ = try await self.call("type", ["ref": ref, "gen": generation, "text": text, "submit": submit]) }
    }

    public func fill(ref: String, generation: Int, value: String) async throws -> BrowserActionDelta {
        try await act { _ = try await self.call("fill", ["ref": ref, "gen": generation, "value": value]) }
    }

    public func select(ref: String, generation: Int, value: String) async throws -> BrowserActionDelta {
        try await act { _ = try await self.call("select", ["ref": ref, "gen": generation, "value": value]) }
    }

    public func hover(ref: String, generation: Int) async throws -> BrowserActionDelta {
        try await act { _ = try await self.call("hover", ["ref": ref, "gen": generation]) }
    }

    public func pressKey(_ key: String) async throws -> BrowserActionDelta {
        try await act { _ = try await self.call("pressKey", ["spec": key]) }
    }

    public func scroll(ref: String?, generation: Int?, direction: String?, amount: Int?) async throws -> BrowserActionDelta {
        try await act {
            _ = try await self.call("scroll", ["ref": ref ?? NSNull(), "gen": generation ?? NSNull(),
                                               "direction": direction ?? "down", "amount": amount ?? NSNull()])
        }
    }

    public func clickAt(x: Double, y: Double) async throws -> BrowserActionDelta {
        try await act { try self.nativeClick(atPageX: x, pageY: y) }
    }

    public func evaluate(_ expression: String) async throws -> String {
        try await call("evaluate", ["expression": expression]) as? String ?? "undefined"
    }

    public func navigate(to url: URL) async throws -> BrowserActionDelta {
        try await act { self.webView.load(URLRequest(url: url)) }
    }

    public func goBack() async throws -> BrowserActionDelta { try await act { self.webView.goBack() } }
    public func goForward() async throws -> BrowserActionDelta { try await act { self.webView.goForward() } }

    /// Runs one action and gathers its delta: arm the mutation counter and
    /// navigation counters, act, wait 300 ms, read what moved.
    private func act(_ body: () async throws -> Void) async throws -> BrowserActionDelta {
        let urlBefore = currentURL, titleBefore = currentTitle
        let startedBefore = navigationsStarted, finishedBefore = navigationsFinished
        let mutationsBefore = (try? await call("mutations") as? Int) ?? 0
        pendingDialog = nil
        try await body()
        try await Task.sleep(nanoseconds: 300_000_000)
        var delta = BrowserActionDelta()
        delta.dialog = pendingDialog
        pendingDialog = nil
        if navigationsStarted > startedBefore || webView.isLoading {
            let deadline = Date().addingTimeInterval(Self.defaultTimeout)
            while webView.isLoading && Date() < deadline { try await Task.sleep(nanoseconds: 100_000_000) }
            if webView.isLoading { delta.pending = true } else { delta.navigated = navigationsFinished > finishedBefore }
            lastSnapshotLines = nil
        }
        if currentURL != urlBefore { delta.url = currentURL }
        if currentTitle != titleBefore { delta.title = currentTitle }
        if delta.navigated { delta.url = currentURL; delta.title = currentTitle }
        let mutationsAfter = (try? await call("mutations") as? Int) ?? mutationsBefore
        delta.changed = delta.navigated || mutationsAfter != mutationsBefore
        if delta.changed && !delta.navigated && !delta.pending,
           let ref = try? await call("focusedLandmark") as? String,
           let raw = try? await call("landmarkSnapshot", ["ref": ref, "depth": 4]),
           let data = try? JSONSerialization.data(withJSONObject: raw as Any),
           let node = try? JSONDecoder().decode(BrowserSnapshotNode.self, from: data) {
            delta.focused = BrowserSnapshotRenderer.render(node, includeURLs: false)
        }
        return delta
    }

    // MARK: Waiting

    public func wait(for condition: BrowserWaitCondition, timeout: TimeInterval?) async throws -> BrowserWaitResult {
        let limit = min(max(timeout ?? Self.defaultTimeout, 0.05), Self.maximumTimeout)
        let deadline = Date().addingTimeInterval(limit)
        var idleSince: Date?
        var lastMutations = -1
        while Date() < deadline {
            let satisfied: Bool
            switch condition {
            case .text(let t): satisfied = (try? await call("hasText", ["needle": t]) as? Bool) ?? false
            case .ref(let r, let g): satisfied = (try? await call("isVisible", ["ref": r, "gen": g]) as? Bool) ?? false
            case .url(let u): satisfied = currentURL.contains(u)
            case .load: satisfied = !webView.isLoading && webView.url != nil
            case .idle:
                let m = (try? await call("mutations") as? Int) ?? -2
                if m != lastMutations { lastMutations = m; idleSince = Date() }
                satisfied = !webView.isLoading && idleSince.map { Date().timeIntervalSince($0) >= 0.5 } == true
            }
            if satisfied { return BrowserWaitResult(satisfied: true, url: currentURL, title: currentTitle) }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw BrowserAutomationError.timeout(condition.description)
    }

    // MARK: Geometry, screenshots, native events

    private func rect(ref: String, generation: Int) async throws -> CGRect {
        guard let r = try await call("rect", ["ref": ref, "gen": generation]) as? [String: Double] else {
            throw BrowserAutomationError.script("no rect for \(ref)")
        }
        return CGRect(x: r["x"] ?? 0, y: r["y"] ?? 0, width: r["width"] ?? 0, height: r["height"] ?? 0)
    }

    public func screenshot(ref: String?, generation: Int?) async throws -> Data {
        let configuration = WKSnapshotConfiguration()
        if let ref, let generation {
            let r = try await rect(ref: ref, generation: generation)
            let zoom = webView.pageZoom
            configuration.rect = CGRect(x: r.minX * zoom, y: r.minY * zoom, width: r.width * zoom, height: r.height * zoom)
        }
        let source = configuration.rect.isNull ? webView.bounds : configuration.rect
        let longest = max(source.width, source.height)
        if longest > Self.maximumScreenshotSide {
            configuration.snapshotWidth = NSNumber(value: Double(source.width * Self.maximumScreenshotSide / longest))
        }
        let image: NSImage = try await withCheckedThrowingContinuation { c in
            webView.takeSnapshot(with: configuration) { image, error in
                if let image { c.resume(returning: image) } else { c.resume(throwing: BrowserAutomationError.script(error?.localizedDescription ?? "snapshot failed")) }
            }
        }
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else {
            throw BrowserAutomationError.script("could not encode the screenshot")
        }
        return png
    }

    /// Mouse down/up through the web view's own responder methods, so WebKit
    /// handles it as a real click. Page coordinates are CSS pixels.
    private func nativeClick(atPageX x: Double, pageY y: Double) throws {
        guard let window = webView.window else { throw BrowserAutomationError.noWindow }
        let zoom = webView.pageZoom
        var point = NSPoint(x: x * zoom, y: y * zoom)
        if !webView.isFlipped { point.y = webView.bounds.height - point.y }
        let inWindow = webView.convert(point, to: nil)
        for (type, number) in [(NSEvent.EventType.leftMouseDown, 1), (.leftMouseUp, 2)] {
            guard let event = NSEvent.mouseEvent(
                with: type, location: inWindow, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: number, clickCount: 1, pressure: 1) else { continue }
            if type == .leftMouseDown { webView.mouseDown(with: event) } else { webView.mouseUp(with: event) }
        }
    }
}
// swiftlint:enable line_length identifier_name
