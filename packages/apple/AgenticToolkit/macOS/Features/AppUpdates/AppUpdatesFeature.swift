import AppKit

/// "Check for Updates…" in the app menu and the status menu, and the
/// "Install Updates Automatically" choice beside it in the status menu.
///
/// There is no feature without an updater (`init?(updater: nil)` is nil): an
/// app with no feed or signing key gets no item at all, rather than one that is
/// greyed out for a reason its user cannot act on.
///
/// The status menu carries both because an accessory app has no menu bar of its
/// own until it is frontmost, so its status menu is where people look.
///
/// The toggle appears only where the updater checks in the background. In the
/// dev channel nothing ever checks unasked, so "install automatically" would be
/// a checkmark that changes nothing.
@MainActor
public final class AppUpdatesFeature: AppFeature {
    private let checkForUpdates: () -> Void
    private let canCheckForUpdates: () -> Bool
    private let installsUpdatesAutomatically: () -> Bool
    private let setInstallsUpdatesAutomatically: (Bool) -> Void

    public convenience init?(updater: AppUpdater?) {
        guard let updater else { return nil }
        self.init(
            checkForUpdates: { updater.checkForUpdates() },
            canCheckForUpdates: { updater.canCheckForUpdates },
            installsUpdatesAutomatically: { updater.installsUpdatesAutomatically },
            setInstallsUpdatesAutomatically: { updater.installsUpdatesAutomatically = $0 },
            offersAutomaticInstall: updater.configuration.checksInBackground)
    }

    /// The updater's four operations as closures, so a test drives the menu
    /// contract without starting Sparkle.
    init(
        checkForUpdates: @escaping () -> Void,
        canCheckForUpdates: @escaping () -> Bool,
        installsUpdatesAutomatically: @escaping () -> Bool,
        setInstallsUpdatesAutomatically: @escaping (Bool) -> Void,
        offersAutomaticInstall: Bool
    ) {
        self.checkForUpdates = checkForUpdates
        self.canCheckForUpdates = canCheckForUpdates
        self.installsUpdatesAutomatically = installsUpdatesAutomatically
        self.setInstallsUpdatesAutomatically = setInstallsUpdatesAutomatically
        super.init()

        // Section 2: after the sections other features fill (Notes 0, AI Chat and
        // Terminal 1), so these two form their own group above Quit.
        let checkTitle = "Check for Updates…"
        // The app menu's contributions follow About directly, so order 0 puts
        // this item right under it.
        menuContributions = [
            MenuContribution(
                slot: .app, title: checkTitle, order: 0,
                isEnabled: { canCheckForUpdates() },
                action: { checkForUpdates() }),
            MenuContribution(
                slot: .statusItem(section: 2), title: checkTitle, order: 0,
                isEnabled: { canCheckForUpdates() },
                action: { checkForUpdates() })
        ]
        if offersAutomaticInstall {
            menuContributions.append(MenuContribution(
                slot: .statusItem(section: 2), title: "Install Updates Automatically", order: 10,
                isChecked: { installsUpdatesAutomatically() },
                identifier: "install-automatically",
                action: { setInstallsUpdatesAutomatically(!installsUpdatesAutomatically()) }))
        }
    }
}
