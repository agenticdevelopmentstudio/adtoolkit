import AppKit
import Combine

import AgenticDeveloperToolkitUI
import AgenticToolkitCore

/// The Automation settings panel: whether models may drive browser panes,
/// whether `browser_evaluate` is allowed, and how to reach the endpoint.
@MainActor
public final class AutomationSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    private let status: AutomationServerStatus
    private let settings: SettingsStore

    public init(status: AutomationServerStatus, settings: SettingsStore = UserSettings.shared) {
        self.status = status
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Automation",
            icon: NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Automation",
                  body: "A model — Claude Code in a terminal pane, or the app's own chat — can drive "
                      + "the Browser pane: read the page, click, type, and take screenshots. "
                      + "Browser says what it may do; Endpoint says how it connects.")
        ])
    }

    public override var searchKeywords: [String] { AutomationBrowserPanel.keywords + AutomationEndpointPanel.keywords }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addPanel(AutomationBrowserPanel())
        addPanel(AutomationEndpointPanel(status: status))
    }
}

@MainActor
private class AutomationTopicPanel: ComposableSettings.SettingsPanelViewController {
    init(title: String, symbol: String) {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: title, icon: NSImage(systemSymbolName: symbol, accessibilityDescription: nil)))
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Browser

@MainActor
private final class AutomationBrowserPanel: AutomationTopicPanel {
    static let keywords = ["automation", "model", "drive", "browser", "evaluate", "javascript", "mcp"]
    override var searchKeywords: [String] { Self.keywords }

    init() { super.init(title: "Browser", symbol: "globe") }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Let models drive browser panes",
                  body: "Off, a model can still list the browser panes but cannot read or act on them."),
            .init(title: "Allow browser_evaluate",
                  body: "Lets a model run JavaScript it wrote in a page. Off by default: every other "
                      + "tool is bounded by what the page offers; this one is not.")
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Browser Panes")

        let enabled = ComposableSettings.ViewModel<Bool>(
            title: "Let models drive browser panes",
            setting: UserSettings.browserAutomationEnabled,
            explanation: "Off, a model can list browser panes but not read or act on them.")
        let enabledView = ComposableSettings.CheckboxView(with: enabled)
        _ = enabledView.toggle.accessibilityID("settings.automation.enabled")
        group.addSettingSubview(enabledView)

        let evaluate = ComposableSettings.ViewModel<Bool>(
            title: "Allow browser_evaluate",
            setting: UserSettings.browserAutomationEvaluate,
            explanation: "Lets a model run its own JavaScript in a page.")
        let evaluateView = ComposableSettings.CheckboxView(with: evaluate)
        _ = evaluateView.toggle.accessibilityID("settings.automation.evaluate")
        group.addSettingSubview(evaluateView)

        settingsView.addGroup(group)
    }
}

// MARK: - Endpoint

@MainActor
private final class AutomationEndpointPanel: AutomationTopicPanel {
    static let keywords = ["endpoint", "port", "token", "claude code", "register", "mcp"]
    override var searchKeywords: [String] { Self.keywords }

    private let status: AutomationServerStatus
    private let line = NSTextField(labelWithString: "")
    private let copyButton = NSButton(title: "Copy Claude Code Command", target: nil, action: nil)
    private var cancellables: Set<AnyCancellable> = []

    init(status: AutomationServerStatus) {
        self.status = status
        super.init(title: "Endpoint", symbol: "network")
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Endpoint",
                  body: "The app serves its tools over MCP on this Mac only. Claude Code run from a "
                      + "terminal pane finds it through the shell's environment; Claude Code run "
                      + "anywhere else needs the command below, once.")
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "MCP Endpoint")

        line.lineBreakMode = .byWordWrapping
        line.maximumNumberOfLines = 0
        _ = line.accessibilityID("settings.automation.status")
        group.addSettingSubview(line)

        copyButton.target = self
        copyButton.action = #selector(copyCommand)
        _ = copyButton.accessibilityID("settings.automation.copy-command")
        group.addSettingSubview(copyButton)

        settingsView.addGroup(group)

        // @Published publishes the new value before it is stored, so render
        // from the published values themselves: reading `status` here would
        // show the old ones.
        Publishers.CombineLatest4(status.$port, status.$token, status.$isRegistered, status.$failureReason)
            .sink { [weak self] port, token, isRegistered, failureReason in
                self?.render(port: port, token: token, isRegistered: isRegistered, failureReason: failureReason)
            }
            .store(in: &cancellables)
    }

    private func render(port: UInt16?, token: String?, isRegistered: Bool, failureReason: String?) {
        line.stringValue = AutomationServerStatus.line(
            port: port, isRegistered: isRegistered, failureReason: failureReason)
        copyButton.isEnabled = port != nil && token != nil
    }

    @objc private func copyCommand() {
        guard let port = status.port, let token = status.token else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(MCPRegistration.claudeCommand(port: port, token: token), forType: .string)
    }
}
