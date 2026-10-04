import AppKit

/// Runs `alert` modally from a run-loop block and returns the response.
///
/// A plain `NSAlert.runModal()` entered inline from async main-actor code
/// shows blank controls: a main-actor task is a main-queue block, and dispatch
/// will not re-enter the main queue underneath one. A run-loop block is not a
/// main-queue block, so the modal session can drain the queue. Same pattern as
/// `PermissionWalkthrough.presentFromRunLoop` and `ModalProgressPanel.begin`.
@MainActor
public func runAlertFromRunLoop(
    _ alert: NSAlert,
    run: @escaping @MainActor (NSAlert) -> NSApplication.ModalResponse = { $0.runModal() }
) async -> NSApplication.ModalResponse {
    await withCheckedContinuation { continuation in
        RunLoop.main.perform(inModes: [.common]) {
            MainActor.assumeIsolated {
                continuation.resume(returning: run(alert))
            }
        }
    }
}
