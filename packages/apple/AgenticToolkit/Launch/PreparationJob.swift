/// Assesses state while the user waits — fast, read-only, never prompting —
/// and returns the startup jobs that state calls for (often none).
public protocol PreparationJob: Sendable {
    func assess() async -> [any StartupJob]
}
