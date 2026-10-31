import AppKit
import Combine
import SwiftUI
import AgenticToolkitCore
import os

/// What the "Needs you" pane shows: the store's attention items, split into
/// those still waiting on someone and those done within the retention period.
///
/// A view of the store and nothing more. It reloads whenever the store reports
/// an attention write, from whichever side made it, and hands every button
/// press to its callbacks; the window turns those into controller calls.
@MainActor
public final class AttentionPaneModel: ObservableObject {

    /// What a card offers, from its kind and state.
    public enum CardAction: Equatable, Sendable {
        case discuss, resolved, confirm
        /// The button's line is on its way to the partner.
        case sending
        case done
    }

    /// Open, discussing and sent items, newest first.
    @Published public private(set) var open: [AttentionItem] = []
    /// Done items completed within the retention period.
    @Published public private(set) var done: [AttentionItem] = []

    public var onDiscuss: ((String) -> Void)?
    public var onResolved: ((String) -> Void)?
    public var onConfirm: ((String) -> Void)?
    public var onOpenReference: (([String: String]) -> Void)?

    private let store: PartnerStore
    private let retentionDays: () -> Int
    private var subscription: AnyCancellable?

    public init(store: PartnerStore, retentionDays: @escaping () -> Int) {
        self.store = store
        self.retentionDays = retentionDays
        // `changes` fires on the writing thread; the published arrays are the main actor's.
        subscription = store.changes
            .filter { $0 == .attention }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.reload() } }
        reload()
    }

    public func reload() {
        let cutoff = Date().addingTimeInterval(-TimeInterval(retentionDays()) * 86_400)
        do {
            let items = try store.attentionItems(includeDoneCompletedAfter: cutoff)
            open = items.filter { $0.state != .done }
            done = items.filter { $0.state == .done }
        } catch {
            Self.logger.error("Loading attention items failed: \(error.localizedDescription)")
        }
    }

    /// Discuss for an open question, Resolved for a question under discussion and for an open blocked item,
    /// Confirm for an open notification; a progress indicator while sent, a check when done.
    public static func cardAction(for item: AttentionItem) -> CardAction {
        switch (item.state, item.kind) {
        case (.done, _): return .done
        case (.sent, _): return .sending
        case (.open, .question): return .discuss
        case (.discussing, .question), (.open, .blocked): return .resolved
        case (.open, .notification): return .confirm
        case (.discussing, _): return .resolved
        }
    }

    func perform(_ action: CardAction, on item: AttentionItem) {
        switch action {
        case .discuss: onDiscuss?(item.id)
        case .resolved: onResolved?(item.id)
        case .confirm: onConfirm?(item.id)
        case .sending, .done: break
        }
    }
}

extension AttentionPaneModel: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// Hosts ``AttentionPaneView`` as the window's inspector column.
@MainActor
public final class AttentionPaneViewController: NSHostingController<AttentionPaneView> {

    public let model: AttentionPaneModel

    public init(model: AttentionPaneModel) {
        self.model = model
        super.init(rootView: AttentionPaneView(model: model))
    }

    @available(*, unavailable)
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
