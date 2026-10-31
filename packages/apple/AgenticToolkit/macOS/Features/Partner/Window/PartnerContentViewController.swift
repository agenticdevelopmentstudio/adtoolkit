import AppKit
import AgenticToolkitCore
import os

/// The Coding Partner's middle column: the partner's transcript, a live
/// session's terminal, or a closed session's final screen.
///
/// The transcript's `ChatView` is made once and kept, since its view model is
/// the partner chat session's one subscriber; a session's terminal is the
/// session's own view controller, borrowed while its row is selected.
@MainActor
public final class PartnerContentViewController: NSViewController {

    /// The partner transcript, for prefilling and focusing the composer.
    public let chatView: ChatView

    private var shown: NSView?
    private var borrowed: NSViewController?

    /// - Parameter route: where the composer's text goes. The window routes it to the partner, wrapped when
    ///   a discussion is in progress.
    init(controller: PartnerController, route: @escaping @MainActor (String) -> Void) {
        let initial: [ChatMessage]
        do { initial = try controller.store.transcript(limit: 200) } catch {
            Self.logger.error("Loading the partner transcript failed: \(error.localizedDescription)")
            initial = []
        }
        let session = PartnerComposerSession(base: controller.chatSession, route: route)
        chatView = ChatView(viewModel: AIChatViewModel(session: session, initial: initial))
        chatView.bubbleStyle = .speaker
        chatView.setAccessibilityIdentifier("partner.transcript")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        view = NSView()
        showPartner()
    }

    public func showPartner() {
        install(chatView, borrowing: nil)
    }

    /// A live session: its own terminal view, which the owner can type into.
    public func show(session: PartnerSession) {
        install(session.viewController.view, borrowing: session.viewController)
    }

    /// A closed session: its final screen, read-only.
    public func showClosed(_ record: PartnerStore.SessionRecord) {
        let scroll = NSTextView.scrollableTextView()
        scroll.setAccessibilityIdentifier("partner.finalScreen")
        if let text = scroll.documentView as? NSTextView {
            text.isEditable = false
            text.isSelectable = true
            text.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            text.textContainerInset = NSSize(width: 8, height: 8)
            text.string = record.finalScreen ?? "This session closed without a final screen."
        }
        install(scroll, borrowing: nil)
    }

    private func install(_ content: NSView, borrowing child: NSViewController?) {
        guard content !== shown else { return }
        shown?.removeFromSuperview()
        if let borrowed, borrowed !== child { borrowed.removeFromParent() }
        if let child, child.parent !== self {
            child.removeFromParent()
            addChild(child)
        }
        borrowed = child
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        shown = content
    }
}

extension PartnerContentViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// The partner chat session as the composer sees it: events and interrupt are the session's own,
/// `close` is the controller's, and only `send` goes through the window, which may wrap the text before it
/// reaches the partner.
private final class PartnerComposerSession: ChatSession, @unchecked Sendable {
    private let base: PartnerChatSession
    private let route: @MainActor (String) -> Void

    init(base: PartnerChatSession, route: @escaping @MainActor (String) -> Void) {
        self.base = base
        self.route = route
    }

    func events() -> AsyncStream<ChatEvent> { base.events() }
    func send(_ text: String) {
        let route = route
        Task { @MainActor in route(text) }
    }
    func interrupt() { base.interrupt() }
    /// The controller owns the session; a view going away does not end it.
    func close() {}
}
