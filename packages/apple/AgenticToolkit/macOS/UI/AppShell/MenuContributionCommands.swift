import AppKit
import AgenticDeveloperToolkitUI

/// Turns features' `MenuContribution`s into the `MainMenuCommand`s that
/// `StandardMainMenu` splices into its slots, so a host gets the standard menu
/// bar plus every feature's commands without hand-rolling either.
///
/// ```swift
/// let contributed = MenuContributionCommands(features.flatMap(\.menuContributions))
/// let bar = StandardMainMenu.install(.init(
///     appName: name,
///     appCommands: contributed.commands(for: .app),
///     fileCommands: contributed.commands(for: .file),
///     viewCommands: contributed.commands(for: .view),
///     windowCommands: contributed.commands(for: .window)
/// ))
/// contributed.attach(to: bar)
/// ```
///
/// `MainMenuCommand` holds its target weakly, so this object owns the
/// `ClosureMenuItemTarget` behind every item: the host keeps it for as long as
/// the menu bar it built is installed.
@MainActor
public final class MenuContributionCommands {

    private let contributions: [MenuContribution.Slot: [MenuContribution]]
    private var targets: [ClosureMenuItemTarget] = []
    /// `isHidden` rules, keyed by the target their item will carry: the item
    /// itself does not exist until `StandardMainMenu` builds it.
    private var hiddenRules: [ObjectIdentifier: () -> Bool] = [:]
    private var updateDelegates: [MenuUpdateDelegate] = []

    public init(_ contributions: [MenuContribution]) {
        self.contributions = Dictionary(grouping: contributions, by: \.slot)
    }

    /// One slot's contributions, in `order`. Each call builds fresh targets,
    /// so call it once per slot per menu bar.
    public func commands(for slot: MenuContribution.Slot) -> [MainMenuCommand] {
        (contributions[slot] ?? []).sorted { $0.order < $1.order }.map(command)
    }

    /// Wires `isHidden` into the built menu bar. Hiding is re-asked each time a
    /// menu opens, which only a menu delegate sees — so this runs on the result
    /// of `StandardMainMenu.install`, once its items exist. A menu that already
    /// has a delegate is left alone, and its contributions stay visible.
    public func attach(to menuBar: NSMenu) {
        guard !hiddenRules.isEmpty else { return }
        for container in menuBar.items {
            guard let menu = container.submenu, menu.delegate == nil else { continue }
            let delegate = MenuUpdateDelegate()
            for item in menu.items {
                guard let target = item.target as? ClosureMenuItemTarget,
                      let isHidden = hiddenRules[ObjectIdentifier(target)] else { continue }
                delegate.add(item, isHidden: isHidden)
            }
            guard !delegate.isEmpty else { continue }
            menu.delegate = delegate
            updateDelegates.append(delegate)
        }
    }

    private func command(_ contribution: MenuContribution) -> MainMenuCommand {
        let target = ClosureMenuItemTarget(action: contribution.action, isEnabled: contribution.isEnabled)
        targets.append(target)
        if let isHidden = contribution.isHidden {
            hiddenRules[ObjectIdentifier(target)] = isHidden
        }
        return MainMenuCommand(
            contribution.title,
            action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
            target: target,
            key: contribution.key,
            modifiers: contribution.modifiers
        )
    }
}
