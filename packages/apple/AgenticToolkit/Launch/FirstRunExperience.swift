/// What a first launch shows. `start()` returns when the experience is over —
/// installed, declined or closed — with the jobs it wants run.
@MainActor
public protocol FirstRunExperience: AnyObject {
    func start() async -> [any StartupJob]
}
