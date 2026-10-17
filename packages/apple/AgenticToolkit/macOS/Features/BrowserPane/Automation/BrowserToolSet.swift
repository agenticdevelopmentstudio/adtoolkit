import Foundation
import AgenticToolkitCore

/// The twenty `browser_*` tools. A `ChatToolSource`, so the same object
/// serves the in-app chats and the MCP server.
public final class BrowserToolSet: ChatToolSource, @unchecked Sendable {

    public static let toolNames = [
        "browser_list", "browser_open", "browser_navigate", "browser_back", "browser_forward",
        "browser_snapshot", "browser_text", "browser_find", "browser_click", "browser_type", "browser_fill",
        "browser_select", "browser_press_key", "browser_hover", "browser_scroll", "browser_wait_for",
        "browser_screenshot", "browser_click_at", "browser_console", "browser_evaluate"
    ]

    private let directory: any BrowserPaneDirectory
    private let settings: SettingsStore

    @MainActor
    public init(directory: any BrowserPaneDirectory, settings: SettingsStore = UserSettings.shared) {
        self.directory = directory
        self.settings = settings
    }

    // MARK: ChatToolSource

    public func toolDefinitions() async -> [ToolDefinition] { Self.definitions }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        guard Self.toolNames.contains(name) else { return ("unknown tool \(name)", true) }
        let arguments: [String: Any]
        if argumentsJSON.isEmpty {
            arguments = [:]
        } else if let object = try? JSONSerialization.jsonObject(with: argumentsJSON) as? [String: Any] {
            arguments = object
        } else {
            return ("\(name) arguments are not valid JSON", true)
        }
        let parsed = Arguments(tool: name, values: arguments)
        do {
            // The hop to the main actor is an unstructured task, so cancellation
            // is forwarded to it by hand; otherwise a 60 s wait_for runs on to
            // its end. Over HTTP it arrives from MCPHTTPEndpoint, which turns a
            // caller's notifications/cancelled and FlyingFox's request timeout
            // alike into a cancellation of the SDK's handler task; in a chat it
            // is the stopped turn.
            let work = Task { @MainActor in try await self.dispatch(name, parsed, caller: caller) }
            let reply = try await withTaskCancellationHandler {
                try await work.value
            } onCancel: {
                work.cancel()
            }
            return (reply, false)
        } catch let error as BrowserAutomationError {
            return (error.description, true)
        } catch let error as ToolError {
            return (error.sentence, true)
        } catch {
            return ("\(name) failed: \(error.localizedDescription)", true)
        }
    }

    // MARK: Arguments

    struct ToolError: Error { let sentence: String }

    struct Arguments: @unchecked Sendable {
        let tool: String
        let values: [String: Any]

        func string(_ key: String) throws -> String {
            guard let text = values[key] as? String, !text.isEmpty else {
                throw ToolError(sentence: "\(tool) needs \(key)")
            }
            return text
        }

        /// A required string that may be empty: `browser_fill` with "" clears
        /// the field. A missing, null, numeric or boolean value is still an
        /// error, never a silent "".
        func text(_ key: String) throws -> String {
            guard let text = values[key] as? String else {
                throw ToolError(sentence: "\(tool) needs \(key) as a string")
            }
            return text
        }

        /// An absent key and an empty string both read as "not given".
        func optionalString(_ key: String) -> String? {
            guard let text = values[key] as? String, !text.isEmpty else { return nil }
            return text
        }

        func int(_ key: String) throws -> Int {
            guard let number = optionalInt(key) else { throw ToolError(sentence: "\(tool) needs \(key)") }
            return number
        }

        /// Nil for a missing key, a non-number, a fraction, NaN, infinity or a value outside `Int`.
        func optionalInt(_ key: String) -> Int? {
            guard let number = optionalDouble(key) else { return nil }
            return Int(exactly: number)
        }

        /// Nil for a missing key, a non-number, NaN or infinity.
        func optionalDouble(_ key: String) -> Double? {
            guard let number = values[key] as? Double, number.isFinite else { return nil }
            return number
        }

        func bool(_ key: String) -> Bool { values[key] as? Bool ?? false }

        func url(_ key: String) throws -> URL {
            let raw = try string(key)
            guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" || raw == "about:blank" else {
                throw ToolError(sentence: "only http and https URLs can be opened")
            }
            return url
        }

        /// The optional `ref` with its `generation`: a ref without a generation is refused,
        /// because Task 2 would otherwise ignore the ref and act on the whole page.
        func optionalRefAndGeneration() throws -> (ref: String?, generation: Int?) {
            guard let ref = optionalString("ref") else { return (nil, nil) }
            return (ref, try int("generation"))
        }
    }

    // MARK: Pane resolution

    @MainActor
    private func resolvePane(_ args: Arguments, caller: String?) throws -> BrowserPaneHandle {
        if let id = args.optionalString("pane_id") {
            guard let pane = directory.browserPane(id: id) else {
                throw ToolError(sentence: "pane \(id) was closed; call browser_list")
            }
            return try guardDrivable(pane)
        }
        if let caller, let pane = directory.browserPane(besidePane: caller) { return try guardDrivable(pane) }
        if let pane = directory.lastUsedBrowserPane() { return try guardDrivable(pane) }
        if let pane = directory.browserPanes().first { return try guardDrivable(pane) }
        throw ToolError(sentence: "no browser pane is open; call browser_open")
    }

    /// Refuses a pane showing a local file before the call is queued, naming
    /// the pane. `BrowserAutomation` enforces the same rule again at the moment
    /// each call runs, which is what holds when the page changes meanwhile.
    @MainActor
    private func guardDrivable(_ pane: BrowserPaneHandle) throws -> BrowserPaneHandle {
        if !BrowserAutomation.isDrivable(pane.url) {
            throw ToolError(sentence: "pane \(pane.id) shows a local file, which models may not drive")
        }
        return pane
    }

    /// The switches, checked when a call actually runs. A call waits at the
    /// pane's drive gate behind earlier callers, and the user may turn
    /// automation off in the meantime; the check at queue time alone would
    /// let the queued call through.
    @MainActor
    private func requireSwitches(for name: String) throws {
        try requireEnabled()
        if name == "browser_evaluate" { try requireEvaluateEnabled() }
    }

    @MainActor
    private func requireEnabled() throws {
        guard settings.get(UserSettings.browserAutomationEnabled) else {
            throw ToolError(sentence: "browser automation is turned off in Settings")
        }
    }

    @MainActor
    private func requireEvaluateEnabled() throws {
        guard settings.get(UserSettings.browserAutomationEvaluate) else {
            throw ToolError(sentence: "browser_evaluate is turned off in Settings")
        }
    }

    // MARK: Dispatch

    @MainActor
    private func dispatch(_ name: String, _ args: Arguments, caller: String?) async throws -> String {
        if name == "browser_list" { return listPanes(caller: caller) }
        try requireSwitches(for: name)
        if name == "browser_open" {
            let url = args.optionalString("url") == nil ? openWithoutURLPage() : try args.url("url")
            let pane = try directory.openBrowserPane(besidePane: caller)
            return try await pane.automation.drive {
                try self.requireSwitches(for: name)
                let delta = try await pane.automation.navigate(to: url)
                return "opened pane \(pane.id)\n" + delta.rendered()
            }
        }
        let automation = try resolvePane(args, caller: caller).automation
        return try await automation.drive {
            try self.requireSwitches(for: name)
            if let reply = try await self.dispatchNavigation(name, args, automation) { return reply }
            if let reply = try await self.dispatchReading(name, args, automation) { return reply }
            if let reply = try await self.dispatchActions(name, args, automation) { return reply }
            throw ToolError(sentence: "unknown tool \(name)")
        }
    }

    /// What `browser_open` loads when no URL is given: the Home Page setting
    /// when it names an http or https page, else a blank page. A home page of
    /// any other scheme is not one a model may be handed (`file:` panes are
    /// refused everywhere else), so it falls to blank too.
    @MainActor
    private func openWithoutURLPage() -> URL {
        if let home = BrowserSettings.homePage(in: settings),
           let scheme = home.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return home
        }
        return BrowserPaneViewController.blankPage
    }

    @MainActor
    private func dispatchNavigation(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation
    ) async throws -> String? {
        switch name {
        case "browser_navigate": return try await automation.navigate(to: try args.url("url")).rendered()
        case "browser_back": return try await automation.goBack().rendered()
        case "browser_forward": return try await automation.goForward().rendered()
        default: return nil
        }
    }

    @MainActor
    private func dispatchReading(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation
    ) async throws -> String? {
        switch name {
        case "browser_snapshot":
            var options = BrowserSnapshotOptions()
            options.interactiveOnly = args.bool("interactive_only")
            options.depth = args.optionalInt("depth")
            options.scope = args.optionalString("scope")
            options.includeURLs = args.bool("include_urls")
            options.delta = args.bool("delta")
            let snap = try await automation.snapshot(options)
            return "url: \(snap.url)\ntitle: \(snap.title)\ngeneration: \(snap.generation)\n\n\(snap.text)"
        case "browser_text":
            return try await automation.text(scope: args.optionalString("scope"))
        case "browser_find":
            let matches = try await automation.find(try args.string("text"))
            if matches.isEmpty { return "no element matches" }
            return matches.map { "\($0.ref) \($0.role) \"\($0.name)\"" }.joined(separator: "\n")
        case "browser_wait_for":
            let condition = try waitCondition(args)
            let result = try await automation.wait(for: condition, timeout: args.optionalDouble("timeout"))
            return "satisfied\nurl: \(result.url)\ntitle: \(result.title)"
        case "browser_screenshot":
            let target = try args.optionalRefAndGeneration()
            let png = try await automation.screenshot(ref: target.ref, generation: target.generation)
            return "data:image/png;base64," + png.base64EncodedString()
        case "browser_console":
            let messages = automation.console.messages(level: args.optionalString("level"))
            if messages.isEmpty { return "no console messages" }
            return messages.map { "[\($0.level)] \($0.text)" }.joined(separator: "\n")
        case "browser_evaluate":
            return try await automation.evaluate(try args.string("expression"))
        default:
            return nil
        }
    }

    @MainActor
    private func dispatchActions(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation
    ) async throws -> String? {
        switch name {
        case "browser_click":
            return try await automation.click(
                ref: try args.string("ref"), generation: try args.int("generation"), native: args.bool("native")
            ).rendered()
        case "browser_type":
            return try await automation.type(
                ref: try args.string("ref"), generation: try args.int("generation"),
                text: try args.string("text"), submit: args.bool("submit")
            ).rendered()
        case "browser_fill":
            return try await automation.fill(
                ref: try args.string("ref"), generation: try args.int("generation"),
                value: try args.text("value")
            ).rendered()
        case "browser_select":
            return try await automation.select(
                ref: try args.string("ref"), generation: try args.int("generation"), value: try args.string("value")
            ).rendered()
        case "browser_press_key":
            return try await automation.pressKey(try args.string("key")).rendered()
        case "browser_hover":
            return try await automation.hover(
                ref: try args.string("ref"), generation: try args.int("generation")
            ).rendered()
        case "browser_scroll":
            let target = try args.optionalRefAndGeneration()
            return try await automation.scroll(
                ref: target.ref, generation: target.generation,
                direction: args.optionalString("direction"), amount: args.optionalInt("amount")
            ).rendered()
        case "browser_click_at":
            guard let xPoint = args.optionalDouble("x"), let yPoint = args.optionalDouble("y") else {
                throw ToolError(sentence: "browser_click_at needs x and y")
            }
            return try await automation.clickAt(x: xPoint, y: yPoint).rendered()
        default:
            return nil
        }
    }

    private func waitCondition(_ args: Arguments) throws -> BrowserWaitCondition {
        if let text = args.optionalString("text") { return .text(text) }
        if let ref = args.optionalString("ref") { return .ref(ref, generation: try args.int("generation")) }
        if let url = args.optionalString("url") { return .url(url) }
        if args.bool("load") { return .load }
        if args.bool("idle") { return .idle }
        throw ToolError(sentence: "browser_wait_for needs one of text, ref, url, load, idle")
    }

    @MainActor
    private func listPanes(caller: String?) -> String {
        let panes = directory.browserPanes()
        if panes.isEmpty { return "no browser pane is open; call browser_open" }
        let defaultID = (try? resolvePane(Arguments(tool: "browser_list", values: [:]), caller: caller))?.id
        let rows: [[String: Any]] = panes.map { pane in
            [
                "id": pane.id, "title": pane.title, "url": pane.url, "project": pane.project,
                "tab": pane.tab, "is_default": pane.id == defaultID
            ]
        }
        let data = (try? JSONSerialization.data(withJSONObject: rows, options: [.sortedKeys])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    // MARK: Definitions

    // swiftlint:disable line_length

    private static var paneID: [String: Any] { ToolJSONSchema.string("Browser pane id from browser_list; omit for the default pane") }
    private static var refGen: [String: [String: Any]] { [
        "pane_id": paneID,
        "ref": ToolJSONSchema.string("Element ref from the last browser_snapshot, e.g. e12"),
        "generation": ToolJSONSchema.integer("The generation the ref came from")
    ] }

    private static func tool(_ name: String, _ description: String, _ properties: [String: [String: Any]], required: [String] = []) -> ToolDefinition {
        ToolDefinition(name: name, description: description, parametersJSONSchema: ToolJSONSchema.object(properties: properties, required: required))
    }

    static let definitions: [ToolDefinition] = [
        tool("browser_list", "List the open Browser panes: id, title, url, project, tab, and which one is the default for this caller.", [:]),
        tool("browser_open", "Open a new Browser pane beside the caller and load a URL (http or https), or the home page (else a blank page) when no URL is given.", ["url": ToolJSONSchema.string("The page to load; optional")]),
        tool("browser_navigate", "Load a URL in a Browser pane.", ["url": ToolJSONSchema.string("The page to load"), "pane_id": paneID], required: ["url"]),
        tool("browser_back", "Go back one page.", ["pane_id": paneID]),
        tool("browser_forward", "Go forward one page.", ["pane_id": paneID]),
        tool("browser_snapshot", "The page as an accessibility tree with refs (e1, e2, …) for every interactive element. Take one before acting; refs expire on the next snapshot.", [
            "pane_id": paneID,
            "interactive_only": ToolJSONSchema.boolean("Only elements that can be acted on"),
            "depth": ToolJSONSchema.integer("Maximum tree depth"),
            "scope": ToolJSONSchema.string("A ref or CSS selector to snapshot under"),
            "include_urls": ToolJSONSchema.boolean("Add [url=…] to links"),
            "delta": ToolJSONSchema.boolean("Only lines added or removed since the last snapshot")
        ]),
        tool("browser_text", "The visible text of the page (its main region, else the whole body).", ["pane_id": paneID, "scope": ToolJSONSchema.string("A ref or CSS selector")]),
        tool("browser_find", "Find elements from the last snapshot whose name or text contains the given text.", ["pane_id": paneID, "text": ToolJSONSchema.string("Text to look for, case-insensitive")], required: ["text"]),
        tool("browser_click", "Click an element by ref.", refGen.merging(["native": ToolJSONSchema.boolean("Send a real mouse click instead of a DOM click")]) { $1 }, required: ["ref", "generation"]),
        tool("browser_type", "Type text into an element key by key, appending to what is there.", refGen.merging(["text": ToolJSONSchema.string("Text to type"), "submit": ToolJSONSchema.boolean("Press Enter afterwards")]) { $1 }, required: ["ref", "generation", "text"]),
        tool("browser_fill", "Replace an input's value, firing input and change.", refGen.merging(["value": ToolJSONSchema.string("The new value")]) { $1 }, required: ["ref", "generation", "value"]),
        tool("browser_select", "Choose an option of a select by value or label.", refGen.merging(["value": ToolJSONSchema.string("Option value or label")]) { $1 }, required: ["ref", "generation", "value"]),
        tool("browser_press_key", "Press a key on the focused element: Enter, Escape, Tab, ArrowDown, a, with Meta+/Shift+/Alt+/Control+ prefixes.", ["pane_id": paneID, "key": ToolJSONSchema.string("The key, e.g. Enter or Meta+a")], required: ["key"]),
        tool("browser_hover", "Hover an element by ref.", refGen, required: ["ref", "generation"]),
        tool("browser_scroll", "Scroll an element into view, or scroll the page.", refGen.merging(["direction": ToolJSONSchema.string("up, down, left or right"), "amount": ToolJSONSchema.integer("Pixels")]) { $1 }),
        tool("browser_wait_for", "Wait until text appears, a ref is visible, the URL contains a string, the page loads, or the DOM is idle. Give exactly one of text, ref, url, load, idle.", [
            "pane_id": paneID, "text": ToolJSONSchema.string("Text that must appear"), "ref": ToolJSONSchema.string("Ref that must be visible"),
            "generation": ToolJSONSchema.integer("Generation of the ref"), "url": ToolJSONSchema.string("Substring the URL must contain"),
            "load": ToolJSONSchema.boolean("Wait for the page to finish loading"), "idle": ToolJSONSchema.boolean("Wait for the DOM to stop changing"),
            "timeout": ToolJSONSchema.number("Seconds, default 10, at most 60")
        ]),
        tool("browser_screenshot", "A PNG of the page, or of one element by ref.", refGen),
        tool("browser_click_at", "A real mouse click at page coordinates.", ["pane_id": paneID, "x": ToolJSONSchema.number("CSS pixels from the left"), "y": ToolJSONSchema.number("CSS pixels from the top")], required: ["x", "y"]),
        tool("browser_console", "The page's last console messages and errors.", ["pane_id": paneID, "level": ToolJSONSchema.string("log, info, warn, error or debug")]),
        tool("browser_evaluate", "Evaluate a JavaScript expression in the page and return its JSON. Off unless enabled in Settings.", ["pane_id": paneID, "expression": ToolJSONSchema.string("The expression")], required: ["expression"])
    ]
    // swiftlint:enable line_length
}
