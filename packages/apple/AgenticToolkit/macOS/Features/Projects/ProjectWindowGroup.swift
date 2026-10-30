import Foundation
import Combine

/// The panels a project window's shelf can show, one per button in the bar
/// along its top. More will join them; the raw value is what is persisted, so
/// a new case is added, never renamed.
public enum ProjectShelfPanel: String, Codable, Sendable, CaseIterable {
    /// Every registered project, filterable — choosing one loads it into the
    /// window.
    case browser
    /// The projects this window has open, each kept running whether or not it
    /// is the one on screen.
    case activeProjects

    /// The panel's name, for the button's tooltip and the key command's title.
    public var title: String {
        switch self {
        case .browser: "Project Browser"
        case .activeProjects: "Active Projects"
        }
    }

    /// The SF Symbol on the panel's button.
    public var symbol: String {
        switch self {
        case .browser: "folder"
        case .activeProjects: "square.stack.3d.up"
        }
    }

    /// What the bottom filter field says while this panel is up.
    var filterPlaceholder: String {
        switch self {
        case .browser: "Filter Projects"
        case .activeProjects: "Filter Active Projects"
        }
    }
}

/// One project window as it is persisted — see `UserSettings.projectWindows`.
public struct ProjectWindowState: Codable, Sendable, Equatable {
    public var id: UUID
    public var activeRepoIDs: [UUID]
    public var selectedRepoID: UUID?
    public var panel: ProjectShelfPanel

    public init(
        id: UUID = UUID(),
        activeRepoIDs: [UUID] = [],
        selectedRepoID: UUID? = nil,
        panel: ProjectShelfPanel = .browser
    ) {
        self.id = id
        self.activeRepoIDs = activeRepoIDs
        self.selectedRepoID = selectedRepoID
        self.panel = panel
    }
}

/// A project window as the user sees it: one window, with a list of active
/// projects and one of them on screen.
///
/// Underneath, each active project keeps a window of its own —
/// `ComposableTabsWindowController`, whose identity, saved tabs and running
/// terminals are all per project — and the group shows exactly one of them,
/// swapping which one in place. That is what makes switching instant: nothing
/// is built or torn down, a window is ordered in and another ordered out. With
/// no project active the group shows an `EmptyProjectWindowController`.
///
/// Every window in the group has its own shelf, and every shelf reads this
/// object, so the panel, the active list and the filter text are the same
/// whichever of the windows is the one on screen.
@MainActor
public final class ProjectWindowGroup: ObservableObject, Identifiable {

    public let id: UUID
    @Published public internal(set) var activeRepoIDs: [UUID]
    @Published public internal(set) var selectedRepoID: UUID?
    @Published public var panel: ProjectShelfPanel

    /// What each panel's filter field holds. Not persisted: a filter is a
    /// moment's question, and coming back to a list already narrowed by one
    /// from yesterday reads as projects having gone missing.
    @Published public var filterText: [ProjectShelfPanel: String] = [:]

    public init(state: ProjectWindowState = ProjectWindowState()) {
        self.id = state.id
        self.activeRepoIDs = state.activeRepoIDs
        self.selectedRepoID = state.selectedRepoID
        self.panel = state.panel
    }

    public var state: ProjectWindowState {
        ProjectWindowState(
            id: id,
            activeRepoIDs: activeRepoIDs,
            selectedRepoID: selectedRepoID,
            panel: panel
        )
    }

    public func contains(_ repoID: UUID) -> Bool {
        activeRepoIDs.contains(repoID)
    }

    /// Adds `repoID` after the project on screen, so a project opened from
    /// the browser lands next to the one the user was working in. Idempotent.
    func activate(_ repoID: UUID) {
        guard !contains(repoID) else { return }
        if let selectedRepoID, let index = activeRepoIDs.firstIndex(of: selectedRepoID) {
            activeRepoIDs.insert(repoID, at: index + 1)
        } else {
            activeRepoIDs.append(repoID)
        }
    }

    /// Takes `repoID` out of the active list, and answers which project
    /// should be on screen next if it was the one shown: the one after it, or
    /// failing that the one before, or `nil` for none left.
    @discardableResult
    func deactivate(_ repoID: UUID) -> UUID? {
        guard let index = activeRepoIDs.firstIndex(of: repoID) else { return selectedRepoID }
        activeRepoIDs.remove(at: index)
        guard selectedRepoID == repoID else { return selectedRepoID }
        guard !activeRepoIDs.isEmpty else { return nil }
        return activeRepoIDs[min(index, activeRepoIDs.count - 1)]
    }

    func select(_ repoID: UUID?) {
        if selectedRepoID != repoID { selectedRepoID = repoID }
    }
}
