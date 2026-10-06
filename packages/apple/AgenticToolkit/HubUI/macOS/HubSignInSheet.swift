#if canImport(AppKit)
import AgenticDeveloperToolkit
import AgenticDeveloperToolkitUI
import AgenticToolkitHubService
import AppKit
import os

/// Presents the hub's sign-in screen as a sheet on a window, with a Cancel
/// button, and closes it on sign-in or Cancel.
@MainActor
public enum HubSignInSheet {
    private static let log = Logger(subsystem: "com.agentic-cookbook.toolkit", category: "hub-sign-in")

    public static func present(
        _ model: SignInViewModel,
        from anchor: AccountPresentationAnchor,
        onClose: @escaping @MainActor () -> Void
    ) -> Bool {
        let window: NSWindow? = switch anchor.object {
        case let window as NSWindow: window
        case let controller as NSViewController: controller.view.window
        case let view as NSView: view.window
        default: nil
        }
        guard let window else {
            log.warning("sign-in requested with no window to present on")
            return false
        }
        let container = SignInSheetController(model: model, onClose: onClose)
        let sheet = NSWindow(contentViewController: container)
        sheet.styleMask = [.titled]
        container.sheetWindow = sheet
        window.beginSheet(sheet)
        return true
    }
}

@MainActor
private final class SignInSheetController: NSViewController {
    private let model: SignInViewModel
    private let onClose: @MainActor () -> Void
    weak var sheetWindow: NSWindow?

    init(model: SignInViewModel, onClose: @escaping @MainActor () -> Void) {
        self.model = model
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        model.onSignedIn = { [weak self] _ in self?.close() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func loadView() {
        let signIn = SignInViewController(viewModel: model)
        addChild(signIn)
        let cancel = ThemedActionButton(
            title: "Cancel", style: .secondary, target: self, action: #selector(cancelPressed))
        cancel.keyEquivalent = "\u{1b}"
        cancel.setAccessibilityIdentifier("sign-in.cancel")
        let container = ThemedBackgroundView(role: .windowBackground)
        for sub in [signIn.view, cancel] as [NSView] {
            sub.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(sub)
        }
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 420),
            container.heightAnchor.constraint(equalToConstant: 560),
            signIn.view.topAnchor.constraint(equalTo: container.topAnchor),
            signIn.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            signIn.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            signIn.view.bottomAnchor.constraint(equalTo: cancel.topAnchor, constant: -12),
            cancel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            cancel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        view = container
    }

    @objc private func cancelPressed() { close() }

    private func close() {
        guard let sheet = sheetWindow else { return }
        sheetWindow = nil
        sheet.sheetParent?.endSheet(sheet)
        onClose()
    }
}
#endif
