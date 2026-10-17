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

/// The automations the current call chain is already driving, so a nested
/// `drive` from inside one can tell itself apart from a second caller.
enum BrowserDriveChain {
    @TaskLocal static var held: Set<ObjectIdentifier> = []
}

/// Resumes a continuation exactly once: with WebKit's answer, or with the
/// timeout, whichever comes first. WebKit's callbacks cannot be cancelled, so
/// whichever arrives second finds the continuation gone and is dropped.
@MainActor
private final class Resumer<Value> {
    var continuation: CheckedContinuation<Value, Error>?
    var timer: Task<Void, Never>?

    func finish(_ result: sending Result<Value, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        timer?.cancel()
        continuation.resume(with: result)
    }
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
            let started = change.newValue == true
            Task { @MainActor in
                guard let self else { return }
                if started { self.navigationsStarted += 1 } else { self.navigationsFinished += 1 }
            }
        }
    }

    public var currentURL: String { webView.url?.absoluteString ?? "about:blank" }
    public var currentTitle: String { webView.title ?? "" }

    // MARK: Driving

    /// Every tool call runs inside this so the pane can show its badge and
    /// route dialogs here.
    ///
    /// One caller at a time: the outermost `drive` takes a FIFO gate and holds
    /// it until its body finishes, so a second caller — another Claude Code
    /// process, a persona chat — waits its turn instead of interleaving with
    /// the first at every `await`. An action's dialog and delta then belong to
    /// the caller that caused them. Re-entrant within one call chain: a task
    /// local records which automations the current chain already holds, and a
    /// nested `drive` from that chain passes straight through. The depth count
    /// alone cannot tell the two apart, because a second caller also sees a
    /// non-zero depth while the first is inside. A caller cancelled while it
    /// waits still takes its turn, so the queue stays in order, but then
    /// throws `CancellationError` without running its body: a cancelled tool
    /// call must not act on the page after its caller has gone.
    public func drive<T>(_ body: () async throws -> T) async throws -> T {
        let key = ObjectIdentifier(self)
        if BrowserDriveChain.held.contains(key) { return try await counted(body) }
        await acquireGate()
        defer { releaseGate() }
        try Task.checkCancellation()
        return try await BrowserDriveChain.$held.withValue(BrowserDriveChain.held.union([key])) {
            try await counted(body)
        }
    }

    private var gateHeld = false
    private var gateWaiters: [CheckedContinuation<Void, Never>] = []

    private func acquireGate() async {
        guard gateHeld else {
            gateHeld = true
            return
        }
        await withCheckedContinuation { gateWaiters.append($0) }
    }

    /// Hands the gate straight to the first waiter, which then holds it, so a
    /// caller arriving between the release and the waiter's resumption cannot
    /// jump the queue.
    private func releaseGate() {
        if gateWaiters.isEmpty {
            gateHeld = false
        } else {
            gateWaiters.removeFirst().resume()
        }
    }

    private func counted<T>(_ body: () async throws -> T) async rethrows -> T {
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
            raw = try await webView.callAsyncJavaScript(
                body, arguments: arguments, in: nil, contentWorld: BrowserSnapshotRuntime.world)
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
        // `JSONSerialization.data` raises an Objective-C exception, not a Swift
        // error, on anything that is not JSON (a NaN, a Date), so check first.
        guard JSONSerialization.isValidJSONObject(raw as Any) else {
            throw BrowserAutomationError.script("the snapshot is not JSON")
        }
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

    /// Runs `expression` as the body `return (<expression>);` of an async
    /// function, so a returned Promise is awaited before the value comes back,
    /// and renders the value as JSON (`undefined` when there is none).
    ///
    /// The newlines around the expression keep a trailing `//` comment from
    /// swallowing the closing parenthesis, and one trailing semicolon is
    /// dropped first, since `return (x;)` is a syntax error and a model
    /// writing `document.title;` means the expression, not a statement.
    ///
    /// Gives up after `maximumTimeout`: the caller holds the pane's drive
    /// gate throughout, and a promise that never settles would otherwise hold
    /// it for good, queueing every later tool call on the pane behind it.
    /// WebKit cannot be told to stop, so its answer, if it ever comes, is
    /// dropped.
    public func evaluate(_ expression: String) async throws -> String {
        let body = "return (\n\(Self.expressionBody(expression))\n);"
        let once = Resumer<String>()
        let timeout = Self.maximumTimeout
        do {
            return try await withCheckedThrowingContinuation { c in
                once.continuation = c
                once.timer = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    once.finish(.failure(BrowserAutomationError.timeout("the expression (\(Int(timeout)) s)")))
                }
                Task { @MainActor in
                    do {
                        let value = try await self.webView.callAsyncJavaScript(body, arguments: [:], in: nil, contentWorld: .page)
                        once.finish(.success(Self.renderJSON(value)))
                    } catch {
                        once.finish(.failure(error))
                    }
                }
            }
        } catch let error as BrowserAutomationError {
            throw error
        } catch {
            let message = Self.javaScriptMessage(of: error)
            if Self.isContentSecurityPolicyRefusal(message) { throw BrowserAutomationError.cspRefusesEvaluation }
            throw BrowserAutomationError.script(message)
        }
    }

    /// The expression with surrounding whitespace and one trailing `;` removed.
    static func expressionBody(_ expression: String) -> String {
        var body = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasSuffix(";") {
            body.removeLast()
            body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return body
    }

    /// What WebKit says went wrong: the page's exception message when there
    /// is one, else the error's own description.
    static func javaScriptMessage(of error: Error) -> String {
        let info = (error as NSError).userInfo
        if let message = info["WKJavaScriptExceptionMessage"] as? String, !message.isEmpty { return message }
        return error.localizedDescription
    }

    /// An `EvalError`, or a refusal that names the policy.
    static func isContentSecurityPolicyRefusal(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return lowered.contains("evalerror") || lowered.contains("content security policy")
            || lowered.contains("unsafe-eval")
    }

    /// JSON for a value WebKit handed back. `nil` is JavaScript's `undefined`;
    /// a bare string or number is rendered as a JSON fragment. A value that is
    /// not JSON at all — NaN, Infinity, a Date — is described instead:
    /// `JSONSerialization.data` raises an Objective-C exception on it, which
    /// `try?` cannot catch, so the check comes first. Wrapping the value in an
    /// array lets `isValidJSONObject` answer for a fragment too.
    static func renderJSON(_ value: Any?) -> String {
        guard let value else { return "undefined" }
        if value is NSNull { return "null" }
        guard JSONSerialization.isValidJSONObject([value]),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return String(describing: value) }
        return text
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
        // A #fragment navigation leaves `navigated` false; this URL diff still reports it.
        if currentURL != urlBefore { delta.url = currentURL }
        if currentTitle != titleBefore { delta.title = currentTitle }
        if delta.navigated { delta.url = currentURL; delta.title = currentTitle }
        let mutationsAfter = (try? await call("mutations") as? Int) ?? mutationsBefore
        delta.changed = delta.navigated || mutationsAfter != mutationsBefore
        if delta.changed && !delta.navigated && !delta.pending,
           let ref = try? await call("focusedLandmark") as? String,
           let raw = try? await call("landmarkSnapshot", ["ref": ref, "depth": 4]),
           JSONSerialization.isValidJSONObject(raw as Any),
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

    /// Resamples so the longer side is at most `side` PIXELS (not points: a Retina
    /// snapshot of an 800 pt view is 1600 px).
    static func capped(_ image: CGImage, side: CGFloat) -> CGImage? {
        let longest = CGFloat(max(image.width, image.height))
        guard longest > side else { return image }
        let scale = side / longest
        let width = max(1, Int((CGFloat(image.width) * scale).rounded()))
        let height = max(1, Int((CGFloat(image.height) * scale).rounded()))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// How long `takeSnapshot` may take before the screenshot is given up.
    public static let screenshotTimeout: TimeInterval = 10

    /// Refuses a pane whose view is in no window or in one that is not
    /// visible, and gives up after `screenshotTimeout`: a pane WebKit has
    /// stopped painting can otherwise leave `takeSnapshot` without an answer.
    /// Occlusion is deliberately not checked — a quiet-presentation window is
    /// occluded by design and still screenshots.
    public func screenshot(ref: String?, generation: Int?) async throws -> Data {
        guard let window = webView.window, window.isVisible else { throw BrowserAutomationError.notOnScreen }
        let configuration = WKSnapshotConfiguration()
        if let ref, let generation {
            let r = try await rect(ref: ref, generation: generation)
            let zoom = webView.pageZoom
            configuration.rect = CGRect(x: r.minX * zoom, y: r.minY * zoom, width: r.width * zoom, height: r.height * zoom)
        }
        let once = Resumer<NSImage>()
        let timeout = Self.screenshotTimeout
        let image: NSImage = try await withCheckedThrowingContinuation { c in
            once.continuation = c
            once.timer = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !Task.isCancelled else { return }
                once.finish(.failure(BrowserAutomationError.screenshotTimedOut))
            }
            webView.takeSnapshot(with: configuration) { image, error in
                MainActor.assumeIsolated {
                    if let image {
                        once.finish(.success(image))
                    } else {
                        once.finish(.failure(BrowserAutomationError.script(error?.localizedDescription ?? "snapshot failed")))
                    }
                }
            }
        }
        guard let full = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cg = Self.capped(full, side: Self.maximumScreenshotSide),
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
