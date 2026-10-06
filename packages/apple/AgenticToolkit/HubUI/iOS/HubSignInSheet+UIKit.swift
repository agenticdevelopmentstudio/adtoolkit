#if canImport(UIKit)
import AgenticDeveloperToolkit
import AgenticToolkitHubService
import os
import UIKit

/// Presents the hub's sign-in screen as a form sheet with a Cancel button,
/// and dismisses it on sign-in or Cancel.
@MainActor
public enum HubSignInSheet {
    private static let log = Logger(subsystem: "com.agentic-cookbook.toolkit", category: "hub-sign-in")

    public static func present(
        _ model: SignInViewModel,
        from anchor: AccountPresentationAnchor,
        onClose: @escaping @MainActor () -> Void
    ) -> Bool {
        guard let presenter = anchor.object as? UIViewController else {
            log.warning("sign-in requested with no view controller to present from")
            return false
        }
        // UIKit silently drops a present() when the presenter is already
        // presenting or is not in a window; no close callback would ever fire.
        guard presenter.presentedViewController == nil, presenter.viewIfLoaded?.window != nil else {
            log.warning("sign-in requested but the presenter cannot present right now")
            return false
        }
        let signIn = SignInViewController(viewModel: model)
        let closer = SheetCloser(model: model, onClose: onClose)
        signIn.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak signIn, weak model] _ in
                model?.cancel()
                signIn?.dismiss(animated: true) { closer.close() }
            }
        )
        signIn.navigationItem.leftBarButtonItem?.accessibilityIdentifier = "sign-in.cancel"
        model.onSignedIn = { [weak signIn] _ in
            signIn?.dismiss(animated: true) { closer.close() }
        }
        let nav = UINavigationController(rootViewController: signIn)
        nav.modalPresentationStyle = .formSheet
        nav.presentationController?.delegate = closer
        objc_setAssociatedObject(nav, &SheetCloser.key, closer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        presenter.present(nav, animated: true)
        return true
    }
}

/// Calls `onClose` exactly once, however the sheet goes away (Cancel,
/// sign-in, or a swipe down).
@MainActor
private final class SheetCloser: NSObject, UIAdaptivePresentationControllerDelegate {
    nonisolated(unsafe) static var key: UInt8 = 0
    private var onClose: (@MainActor () -> Void)?
    private weak var model: SignInViewModel?

    init(model: SignInViewModel, onClose: @escaping @MainActor () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    func close() {
        onClose?()
        onClose = nil
    }

    nonisolated func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // A swipe down is a cancel too: stop any sign-in still in flight.
        MainActor.assumeIsolated {
            model?.cancel()
            close()
        }
    }
}
#endif
