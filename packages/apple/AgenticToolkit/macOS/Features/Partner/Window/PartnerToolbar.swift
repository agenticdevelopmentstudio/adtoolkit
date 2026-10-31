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

/// The Coding Partner window's toolbar: the partner's state, enabled jobs and review queue, Start/Stop,
/// Restart, and the inspector toggle that shows or hides "Needs you".
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
    /// Internal for tests.
    let statusLabel = NSTextField(labelWithString: "")
    /// Internal for tests.
    let startStopButton = NSButton()
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
            // Main first: the filter closure is main-actor isolated, and writes arrive from MCP calls off it.
            .receive(on: DispatchQueue.main)
            .filter { $0 == .jobs || $0 == .reviews }
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.refresh(state: self.controller.state)
                }
            }
            .store(in: &subscriptions)
        // Start does nothing while Settings' switch is off, so the button says so instead of failing quietly.
        controller.settings.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == UserSettings.partnerEnabled.name }
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
        // The status line: the state, the enabled jobs, then the review queue.
        // A plain read: the controller seeds missing jobs at start, and the toolbar never writes. Unreadable
        // jobs show as none rather than as the defaults.
        let enabled = ((try? controller.store.jobs()) ?? []).filter(\.isEnabled)
        let queue = (try? controller.store.reviewCounts()).map {
            ReviewQueue(waiting: $0.queued, running: $0.running, done: $0.done)
        }
        let text = Self.statusText(
            state: state, jobs: enabled.map(\.name), queue: queue,
            reviewsEnabled: enabled.contains { $0.id == PartnerJobDefaults.codeReviewsID })
        statusLabel.stringValue = text
        statusLabel.toolTip = text
        let symbol = state.isRunning ? "stop.fill" : "play.fill"
        let title = state.isRunning ? "Stop" : "Start"
        startStopButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        let partnerOn = controller.settings.get(UserSettings.partnerEnabled)
        if state.isRunning || partnerOn {
            startStopButton.toolTip = title
            startStopButton.isEnabled = state != .starting
        } else {
            startStopButton.toolTip = "Turn on the Coding Partner in Settings to start it"
            startStopButton.isEnabled = false
        }
    }

    /// The review counts the status line shows.
    struct ReviewQueue: Equatable {
        var waiting: Int
        var running: Int
        var done: Int
    }

    /// "State · job, job · queue: Q waiting · R running · D done". The queue shows while the code-reviews job
    /// is enabled, and after it is turned off while any review is still listed. Unreadable counts show nothing.
    static func statusText(state: PartnerController.State, jobs: [String], queue: ReviewQueue?,
                           reviewsEnabled: Bool) -> String {
        var parts = [state.displayText]
        if !jobs.isEmpty { parts.append(jobs.joined(separator: ", ")) }
        if let queue, reviewsEnabled || queue != ReviewQueue(waiting: 0, running: 0, done: 0) {
            parts.append("queue: \(queue.waiting) waiting · \(queue.running) running · \(queue.done) done")
        }
        return parts.joined(separator: " · ")
    }

    @objc private func startOrStop() {
        let controller = controller
        Task { @MainActor in
            if controller.state.isRunning { await controller.stop() } else { await controller.start() }
        }
    }

    @objc private func restart() {
        let controller = controller
        Task { @MainActor in await controller.restart(guidelinesChanged: true) }
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
