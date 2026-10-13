// swiftlint:disable line_length identifier_name type_body_length function_body_length cyclomatic_complexity
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

    public func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        await callTool(name: name, argumentsJSON: argumentsJSON, caller: nil)
    }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        guard Self.toolNames.contains(name) else { return ("unknown tool \(name)", true) }
        let arguments: [String: Any]
        if argumentsJSON.isEmpty { arguments = [:] } else if let object = try? JSONSerialization.jsonObject(with: argumentsJSON) as? [String: Any] { arguments = object } else { return ("\(name) arguments are not valid JSON", true) }
        do {
            return (try await Task { @MainActor in try await self.dispatch(name, Arguments(tool: name, values: arguments), caller: caller) }.value, false)
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
            guard let v = values[key] as? String, !v.isEmpty else { throw ToolError(sentence: "\(tool) needs \(key)") }
            return v
        }
        func optionalString(_ key: String) -> String? { values[key] as? String }
        func int(_ key: String) throws -> Int {
            guard let v = values[key] as? Int ?? (values[key] as? Double).map(Int.init) else { throw ToolError(sentence: "\(tool) needs \(key)") }
            return v
        }
        func optionalInt(_ key: String) -> Int? { values[key] as? Int ?? (values[key] as? Double).map(Int.init) }
        func optionalDouble(_ key: String) -> Double? { values[key] as? Double ?? (values[key] as? Int).map(Double.init) }
        func bool(_ key: String) -> Bool { values[key] as? Bool ?? false }
        func url(_ key: String) throws -> URL {
            let raw = try string(key)
            guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" || raw == "about:blank" else {
                throw ToolError(sentence: "only http and https URLs can be opened")
            }
            return url
        }
    }

    // MARK: Pane resolution

    @MainActor
    private func resolvePane(_ a: Arguments, caller: String?) throws -> BrowserPaneHandle {
        if let id = a.optionalString("pane_id") {
            guard let pane = directory.browserPane(id: id) else { throw ToolError(sentence: "pane \(id) was closed; call browser_list") }
            return try guardDrivable(pane)
        }
        if let caller, let pane = directory.browserPane(besidePane: caller) { return try guardDrivable(pane) }
        if let pane = directory.lastUsedBrowserPane() { return try guardDrivable(pane) }
        if let pane = directory.browserPanes().first { return try guardDrivable(pane) }
        throw ToolError(sentence: "no browser pane is open; call browser_open")
    }

    @MainActor
    private func guardDrivable(_ pane: BrowserPaneHandle) throws -> BrowserPaneHandle {
        if pane.url.lowercased().hasPrefix("file:") {
            throw ToolError(sentence: "pane \(pane.id) shows a local file, which models may not drive")
        }
        return pane
    }

    @MainActor
    private func requireEnabled() throws {
        guard settings.get(UserSettings.browserAutomationEnabled) else { throw ToolError(sentence: "browser automation is turned off in Settings") }
    }

    // MARK: Dispatch

    @MainActor
    private func dispatch(_ name: String, _ a: Arguments, caller: String?) async throws -> String {
        if name == "browser_list" { return listPanes(caller: caller) }
        try requireEnabled()
        if name == "browser_open" {
            let url = try a.url("url")
            let pane = try directory.openBrowserPane(besidePane: caller)
            return try await pane.automation.drive {
                let delta = try await pane.automation.navigate(to: url)
                return "opened pane \(pane.id)\n" + delta.rendered()
            }
        }
        let pane = try resolvePane(a, caller: caller)
        let automation = pane.automation
        return try await automation.drive {
            switch name {
            case "browser_navigate":
                return try await automation.navigate(to: try a.url("url")).rendered()
            case "browser_back": return try await automation.goBack().rendered()
            case "browser_forward": return try await automation.goForward().rendered()
            case "browser_snapshot":
                var options = BrowserSnapshotOptions()
                options.interactiveOnly = a.bool("interactive_only")
                options.depth = a.optionalInt("depth")
                options.scope = a.optionalString("scope")
                options.includeURLs = a.bool("include_urls")
                options.delta = a.bool("delta")
                let snap = try await automation.snapshot(options)
                return "url: \(snap.url)\ntitle: \(snap.title)\ngeneration: \(snap.generation)\n\n\(snap.text)"
            case "browser_text": return try await automation.text(scope: a.optionalString("scope"))
            case "browser_find":
                let matches = try await automation.find(try a.string("text"))
                if matches.isEmpty { return "no element matches" }
                return matches.map { "\($0.ref) \($0.role) \"\($0.name)\"" }.joined(separator: "\n")
            case "browser_click":
                return try await automation.click(ref: try a.string("ref"), generation: try a.int("generation"), native: a.bool("native")).rendered()
            case "browser_type":
                return try await automation.type(ref: try a.string("ref"), generation: try a.int("generation"), text: try a.string("text"), submit: a.bool("submit")).rendered()
            case "browser_fill":
                return try await automation.fill(ref: try a.string("ref"), generation: try a.int("generation"), value: a.optionalString("value") ?? "").rendered()
            case "browser_select":
                return try await automation.select(ref: try a.string("ref"), generation: try a.int("generation"), value: try a.string("value")).rendered()
            case "browser_press_key": return try await automation.pressKey(try a.string("key")).rendered()
            case "browser_hover":
                return try await automation.hover(ref: try a.string("ref"), generation: try a.int("generation")).rendered()
            case "browser_scroll":
                return try await automation.scroll(ref: a.optionalString("ref"), generation: a.optionalInt("generation"), direction: a.optionalString("direction"), amount: a.optionalInt("amount")).rendered()
            case "browser_wait_for":
                let condition: BrowserWaitCondition
                if let t = a.optionalString("text") { condition = .text(t) } else if let r = a.optionalString("ref") { condition = .ref(r, generation: try a.int("generation")) } else if let u = a.optionalString("url") { condition = .url(u) } else if a.bool("load") { condition = .load } else if a.bool("idle") { condition = .idle } else { throw ToolError(sentence: "browser_wait_for needs one of text, ref, url, load, idle") }
                let result = try await automation.wait(for: condition, timeout: a.optionalDouble("timeout"))
                return "satisfied\nurl: \(result.url)\ntitle: \(result.title)"
            case "browser_screenshot":
                let png = try await automation.screenshot(ref: a.optionalString("ref"), generation: a.optionalInt("generation"))
                return "data:image/png;base64," + png.base64EncodedString()
            case "browser_click_at":
                guard let x = a.optionalDouble("x"), let y = a.optionalDouble("y") else { throw ToolError(sentence: "browser_click_at needs x and y") }
                return try await automation.clickAt(x: x, y: y).rendered()
            case "browser_console":
                let messages = automation.console.messages(level: a.optionalString("level"))
                if messages.isEmpty { return "no console messages" }
                return messages.map { "[\($0.level)] \($0.text)" }.joined(separator: "\n")
            case "browser_evaluate":
                guard settings.get(UserSettings.browserAutomationEvaluate) else { throw ToolError(sentence: "browser_evaluate is turned off in Settings") }
                return try await automation.evaluate(try a.string("expression"))
            default:
                throw ToolError(sentence: "unknown tool \(name)")
            }
        }
    }

    @MainActor
    private func listPanes(caller: String?) -> String {
        let panes = directory.browserPanes()
        if panes.isEmpty { return "no browser pane is open; call browser_open" }
        let defaultID = (try? resolvePane(Arguments(tool: "browser_list", values: [:]), caller: caller))?.id
        let rows: [[String: Any]] = panes.map { pane in
            ["id": pane.id, "title": pane.title, "url": pane.url, "project": pane.project, "tab": pane.tab, "is_default": pane.id == defaultID]
        }
        let data = (try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    // MARK: Definitions

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
        tool("browser_open", "Open a new Browser pane beside the caller and load a URL (http or https).", ["url": ToolJSONSchema.string("The page to load")], required: ["url"]),
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
}
// swiftlint:enable line_length identifier_name type_body_length function_body_length cyclomatic_complexity
