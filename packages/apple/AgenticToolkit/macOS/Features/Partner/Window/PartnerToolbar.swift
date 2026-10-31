import AppKit
import Combine
import AgenticToolkitCore

extension PartnerController.State {
    /// How the window names the state: the toolbar's status and the shelf's partner row.
    public var displayText: String {
        switch self {
        case .stopped: return "Stopped"
        case .starting: return "Starting…"
        case .idle: return "Idle"
        case .thinking: return "Thinking…"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }

    var isRunning: Bool {
        switch self {
        case .stopped, .failed: return false
        case .starting, .idle, .thinking: return true
        }
    }
}

/// The Coding Partner window's toolbar: the partner's state and enabled jobs, Start/Stop, Restart, and the
/// inspector toggle that shows or hides "Needs you".
///
/// Held by the window controller for the window's life: a toolbar keeps its delegate weakly.
@MainActor
public final class PartnerToolbar: NSObject, NSToolbarDelegate {

    enum ItemID {
        static let status = NSToolbarItem.Identifier("partner.toolbar.status")
        static let startStop = NSToolbarItem.Identifier("partner.toolbar.startStop")
        static let restart = NSToolbarItem.Identifier("partner.toolbar.restart")
    }

    private let controller: PartnerController
    private let statusLabel = NSTextField(labelWithString: "")
    private let startStopButton = NSButton()
    private var subscriptions: Set<AnyCancellable> = []

    public init(controller: PartnerController) {
        self.controller = controller
        super.init()
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.setAccessibilityIdentifier("partner.toolbar.status")
        startStopButton.bezelStyle = .toolbar
        startStopButton.target = self
        startStopButton.action = #selector(startOrStop)
        startStopButton.setAccessibilityIdentifier("partner.toolbar.startStop")

        controller.$state
            .sink { [weak self] state in MainActor.assumeIsolated { self?.refresh(state: state) } }
            .store(in: &subscriptions)
        controller.store.changes
            .filter { $0 == .jobs }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.refresh(state: self.controller.state)
                }
            }
            .store(in: &subscriptions)
    }

    public func install(in window: NSWindow) {
        let toolbar = NSToolbar(identifier: "partner.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }

    /// `state` is passed in: `$state` publishes before the property changes.
    private func refresh(state: PartnerController.State) {
        // The status line: the state, then the enabled jobs.
        // A plain read: the controller seeds missing jobs at start, and the toolbar never writes. Unreadable
        // jobs show as none rather than as the defaults.
        let jobs = ((try? controller.store.jobs()) ?? []).filter(\.isEnabled).map(\.name)
        let text = jobs.isEmpty ? state.displayText : "\(state.displayText) · \(jobs.joined(separator: ", "))"
        statusLabel.stringValue = text
        statusLabel.toolTip = text
        let symbol = state.isRunning ? "stop.fill" : "play.fill"
        let title = state.isRunning ? "Stop" : "Start"
        startStopButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        startStopButton.toolTip = title
        startStopButton.isEnabled = state != .starting
    }

    @objc private func startOrStop() {
        let controller = controller
        Task { @MainActor in
            if controller.state.isRunning { await controller.stop() } else { await controller.start() }
        }
    }

    @objc private func restart() {
        let controller = controller
        Task { @MainActor in await controller.restart() }
    }

    // MARK: - NSToolbarDelegate

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [ItemID.status, .flexibleSpace, ItemID.startStop, ItemID.restart, .inspectorTrackingSeparator,
         .toggleInspector]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case ItemID.status:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Status"
            item.view = statusLabel
            return item
        case ItemID.startStop:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Start/Stop"
            item.view = startStopButton
            return item
        case ItemID.restart:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Restart"
            item.toolTip = "Restart the partner, applying changed guidelines"
            item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Restart")
            item.target = self
            item.action = #selector(restart)
            item.isBordered = true
            return item
        default:
            return nil
        }
    }
}
