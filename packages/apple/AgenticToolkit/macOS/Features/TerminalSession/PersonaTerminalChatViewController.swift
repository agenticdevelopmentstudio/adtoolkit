import AppKit
import AIPluginKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// A chat with an AI persona that can work the user's terminal — by way of
/// the Terminal Chat in the same tab, never the terminal directly. When that
/// chat is connected to a private terminal, the persona only ever sees the
/// terminal's privacy words, never the real ones.
///
/// The persona runs on one of the LLM providers configured in Settings, chosen
/// per pane along with a model and the persona's instructions.
///
/// **Experimental, and deliberately narrow**, like the Terminal Chat itself:
/// "the Terminal Chat" is the first one in this tab.
@MainActor
public final class PersonaTerminalChatViewController: NSViewController {

    private let stateStore: PaneStateStore
    private let pluginManager: AIPluginManager
    private var session: LocalChatSession!
    private var viewModel: AIChatViewModel!
    private var chatView: ChatView?

    /// The pickers in an open Settings sheet, so choosing a provider can
    /// refill the model list beside it.
    private weak var providerPopup: NSPopUpButton?
    private weak var modelPopup: NSPopUpButton?
    private var modelFetch: Task<Void, Never>?

    public init(stateStore: PaneStateStore, pluginManager: AIPluginManager) {
        self.stateStore = stateStore
        self.pluginManager = pluginManager
        super.init(nibName: nil, bundle: nil)
        // Every closure reads the pane's settings at the moment of the turn, so
        // a provider, model or persona changed in Settings applies to the next
        // message without rebuilding the session.
        session = LocalChatSession(
            resolvePlugin: { [weak self] in
                await MainActor.run { self?.resolvePlugin() }
            },
            makeContext: { [weak self] history in
                await MainActor.run { self?.makeContext(history: history) }
                    ?? AIChatContext(messages: history, model: "", config: AIPluginConfig([:]))
            },
            toolSource: TerminalChatToolSource { [weak self] in
                self?.connectedTerminalChat()
            }
        )
        viewModel = AIChatViewModel(session: session)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.frame = NSRect(x: 0, y: 0, width: 360, height: 500)
        let chatView = ChatView(viewModel: viewModel)
        chatView.isInterruptEnabled = true
        chatView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chatView)
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: container.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.chatView = chatView
        view = container
        applyStatus()
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        // The Terminal Chat can only be found once this pane is in the tree.
        applyStatus()
    }

    // MARK: - Settings

    private var isConnectEnabled: Bool {
        get { stateStore.paneStateValue(forKey: Keys.connected) == "1" }
        set { stateStore.setPaneStateValue(newValue ? "1" : nil, forKey: Keys.connected) }
    }

    /// The chosen LLM provider configuration, if it still exists in Settings.
    private var configuration: AIProviderConfiguration? {
        guard let id = stateStore.paneStateValue(forKey: Keys.configurationID) else { return nil }
        return UserSettings.aiProviderConfigurations.currentValue.first { $0.id.uuidString == id }
    }

    /// The model chosen for this pane, or nil for the provider's own.
    private var modelOverride: String? {
        get { stateStore.paneStateValue(forKey: Keys.model) }
        set { stateStore.setPaneStateValue(newValue, forKey: Keys.model) }
    }

    private var persona: String {
        stateStore.paneStateValue(forKey: Keys.persona) ?? Self.defaultPersona
    }

    private static let defaultPersona = """
        You are a capable, careful shell assistant working alongside the user in their macOS \
        terminal. Use run_terminal_command to look around and to do what the user asks, and \
        report back briefly. Never run anything destructive or irreversible — deleting files, \
        force-pushing, changing system settings — unless the user has explicitly asked for that \
        exact thing. If a command is still running, use wait_for_terminal_output or \
        interrupt_terminal.
        """

    // MARK: - Turns

    /// The chosen provider, with the terminal tools described in its prompt —
    /// no provider plugin sends tool definitions natively, and the Claude Code
    /// CLI cannot take custom ones at all.
    private func resolvePlugin() -> (any AIPlugin)? {
        guard let configuration,
              let plugin = try? pluginManager.loadPlugin(identifier: configuration.pluginIdentifier)
        else { return nil }
        return PromptedToolCallingPlugin(wrapping: plugin)
    }

    private func makeContext(history: [AIChatMessage]) -> AIChatContext {
        var values: [String: String] = [:]
        var model = ""
        if let configuration, let resolved = AIProviderResolver.resolve(configuration, manager: pluginManager) {
            values = resolved.values
            model = modelOverride ?? resolved.model
            values["model"] = model
        }
        return AIChatContext(
            messages: history,
            model: model,
            systemPrompt: persona,
            config: AIPluginConfig(values)
        )
    }

    /// The Terminal Chat in this tab, when this pane is set to talk to one.
    private func connectedTerminalChat() -> TerminalChatSession? {
        guard isConnectEnabled else { return nil }
        return tabPaneContents().lazy.compactMap { ($0 as? TerminalChatViewController)?.session }.first
    }

    private func applyStatus() {
        guard let chatView else { return }
        chatView.isComposerEnabled = configuration != nil
        if configuration == nil {
            chatView.setStatus("Choose an LLM provider in this pane's Settings", icon: nil)
        } else if !isConnectEnabled {
            chatView.setStatus("Not connected — turn on Connect to Terminal Chat in this pane's Settings",
                               icon: nil)
        } else if connectedTerminalChat() == nil {
            chatView.setStatus("No Terminal Chat in this tab to connect to", icon: nil)
        } else {
            chatView.setStatus(nil, icon: nil)
        }
    }

    // MARK: - Settings actions

    @objc private func providerChosen(_ sender: NSPopUpButton) {
        let id = sender.selectedItem?.representedObject as? String
        stateStore.setPaneStateValue(id, forKey: Keys.configurationID)
        // A model belongs to the provider it was chosen from.
        modelOverride = nil
        refillModels()
        applyStatus()
    }

    @objc private func modelChosen(_ sender: NSPopUpButton) {
        modelOverride = sender.selectedItem?.representedObject as? String
    }

    @objc private func personaEdited(_ sender: NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        stateStore.setPaneStateValue(text.isEmpty || text == Self.defaultPersona ? nil : text,
                                     forKey: Keys.persona)
    }

    /// Fills the model picker from the provider's listed models, then — for a
    /// provider that serves `/models` — from what it actually offers.
    private func refillModels() {
        modelFetch?.cancel()
        guard let popup = modelPopup else { return }
        guard let configuration,
              let template = pluginManager.template(pluginIdentifier: configuration.pluginIdentifier,
                                                    templateId: configuration.templateId),
              let resolved = AIProviderResolver.resolve(configuration, manager: pluginManager) else {
            fillModels(popup, models: [], providerDefault: nil)
            return
        }
        fillModels(popup, models: template.models, providerDefault: resolved.model)

        guard ModelChooserContent.supportsLiveModels(pluginIdentifier: configuration.pluginIdentifier)
        else { return }
        let baseURL = resolved.values["baseURL"] ?? ""
        let apiKey = resolved.values["apiKey"]
        modelFetch = Task { [weak self] in
            let live = await OpenAIModelCatalog.fetch(baseURL: baseURL, apiKey: apiKey)
            guard !Task.isCancelled, !live.isEmpty, let self, let popup = self.modelPopup else { return }
            self.fillModels(popup, models: live, providerDefault: resolved.model)
        }
    }

    private func fillModels(_ popup: NSPopUpButton, models: [String], providerDefault: String?) {
        popup.removeAllItems()
        let defaultTitle = providerDefault.map { "Provider default (\($0))" } ?? "Provider default"
        popup.addItem(withTitle: defaultTitle)
        popup.lastItem?.representedObject = nil
        var offered = models
        if let modelOverride, !offered.contains(modelOverride) { offered.append(modelOverride) }
        for model in offered {
            popup.addItem(withTitle: model)
            popup.lastItem?.representedObject = model
        }
        if let modelOverride,
           let item = popup.itemArray.first(where: { $0.representedObject as? String == modelOverride }) {
            popup.select(item)
        } else {
            popup.selectItem(at: 0)
        }
    }

    private enum Keys {
        static let connected = "connected"
        static let configurationID = "configurationID"
        static let model = "model"
        static let persona = "persona"
    }
}

extension PersonaTerminalChatViewController: PaneOptionsProviding {

    public func makePaneOptionRows() -> [NSView] {
        let connect = WindowOptionsToggle(
            title: "Connect to Terminal Chat",
            isOn: isConnectEnabled,
            onChange: { [weak self] value in
                self?.isConnectEnabled = value
                self?.applyStatus()
            }
        ).checkboxAccessibilityID("personaTerminalChat.options.connect")

        let provider = NSPopUpButton()
        provider.addItem(withTitle: "None")
        provider.lastItem?.representedObject = nil
        for configuration in UserSettings.aiProviderConfigurations.currentValue {
            provider.addItem(withTitle: configuration.name)
            provider.lastItem?.representedObject = configuration.id.uuidString
        }
        if let id = configuration?.id.uuidString,
           let item = provider.itemArray.first(where: { $0.representedObject as? String == id }) {
            provider.select(item)
        }
        provider.target = self
        provider.action = #selector(providerChosen(_:))
        provider.setAccessibilityIdentifier("personaTerminalChat.options.provider")
        providerPopup = provider

        let model = NSPopUpButton()
        model.target = self
        model.action = #selector(modelChosen(_:))
        model.setAccessibilityIdentifier("personaTerminalChat.options.model")
        modelPopup = model
        refillModels()

        let personaField = NSTextField(string: persona)
        personaField.lineBreakMode = .byWordWrapping
        personaField.usesSingleLineMode = false
        personaField.cell?.wraps = true
        personaField.cell?.isScrollable = false
        personaField.target = self
        personaField.action = #selector(personaEdited(_:))
        // Committed when the field loses focus too, so closing the sheet
        // without pressing Return does not throw the edit away.
        personaField.cell?.sendsActionOnEndEditing = true
        personaField.setAccessibilityIdentifier("personaTerminalChat.options.persona")
        personaField.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true
        personaField.heightAnchor.constraint(equalToConstant: 110).isActive = true

        return [
            connect,
            Self.labeled("LLM provider", provider),
            Self.labeled("Model", model),
            Self.labeled("Persona", personaField)
        ]
    }

    private static func labeled(_ title: String, _ control: NSView) -> NSView {
        let stack = NSStackView(views: [NSTextField(labelWithString: title), control])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }
}

extension PersonaTerminalChatViewController: PaneContentTeardown {
    public func paneContentWillBeDiscarded() {
        modelFetch?.cancel()
        session.close()
    }
}
