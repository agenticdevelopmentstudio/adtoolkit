import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit

/// Singleton window controller for the Coding Partner window: the shelf, the
/// partner's transcript and its sessions' terminals, and "Needs you".
///
/// The Conversations window's recipe: built by ``ensureCurrent(controller:)``
/// without showing so `restoreOnLaunch()` can reopen it, always-on-top from a
/// setting kept live by an observer, and the gear in the title bar.
@MainActor
public final class PartnerWindowController: SingleWindowController {
    public private(set) static var current: PartnerWindowController?

    public static let windowID = "coding-partner"

    /// The window's contents, for the app's wiring and for key commands.
    public let splitViewController: PartnerSplitViewController

    private let toolbar: PartnerToolbar
    private let configDialog: WindowOptionsDialog
    private var floatingObserver: UserSettingObserver<Bool>?

    public static func present(controller: PartnerController) {
        ensureCurrent(controller: controller)
        current?.showWindow()
    }

    /// Constructs the singleton (registering it with `WindowManager.registry`) without showing it.
    public static func ensureCurrent(controller: PartnerController) {
        if current == nil {
            current = PartnerWindowController(controller: controller)
        }
    }

    public override func close() {
        // performClose NSBeeps on a window that isn't visible.
        guard window?.isVisible == true else { return }
        window?.performClose(nil)
    }

    public override func configureWindow(_ window: NSWindow) {
        setFloating(UserSettings.partnerAlwaysOnTop.value)
        floatingObserver = UserSettingObserver(UserSettings.partnerAlwaysOnTop) { [weak self] floating in
            self?.setFloating(floating)
        }
        toolbar.install(in: window)
        window.addTitlebarAccessoryViewController(configDialog.makeTitlebarAccessory())
    }

    private init(controller: PartnerController) {
        let split = PartnerSplitViewController(controller: controller)
        splitViewController = split
        toolbar = PartnerToolbar(controller: controller)
        configDialog = WindowOptionsDialog(title: "Coding Partner Window") {
            [
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: "Always show above other windows",
                        setting: UserSettings.partnerAlwaysOnTop
                    )
                )
            ]
        }

        super.init(windowID: Self.windowID, contentViewController: split)

        self.windowTitle = "Coding Partner"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 1100, height: 720),
            minSize: NSSize(width: 720, height: 420),
            defaultPosition: .center,
            persistsFrame: true
        )
    }
}
