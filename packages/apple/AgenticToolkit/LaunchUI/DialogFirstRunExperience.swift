import AgenticToolkitLaunch

/// The default first-run experience: one app-provided dialog.
@MainActor
public final class DialogFirstRunExperience: FirstRunExperience {
    private let makeDialog: @MainActor () -> FirstRunDialog
    public init(dialog: @escaping @MainActor () -> FirstRunDialog) { makeDialog = dialog }

    public func start() async -> [any StartupJob] {
        switch await makeDialog().runModal() {
        case .confirmed(let jobs): return jobs
        case .cancelled: return []
        }
    }
}
