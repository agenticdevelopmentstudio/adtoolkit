import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit

/// Singleton window controller for the AI Log window — the record of every LLM call
/// the daemon made (session summaries, AI oversight judgments).
@MainActor
public final class AILogWindowController: SingleWindowController {
    public private(set) static var current: AILogWindowController?

    /// Shows the window without activating the app, like every other window
    /// Stenographer opens.
    public static func present(service: any StenographerDaemonService) {
        ensureCurrent(service: service)
        current?.showWindow()
    }

    /// Constructs the singleton controller (registering it with `WindowManager`)
    /// without showing the window, so the toolkit's restore-on-launch can reopen it.
    public static func ensureCurrent(service: any StenographerDaemonService) {
        if current == nil {
            current = AILogWindowController(service: service)
        }
    }

    public override func close() {
        window?.performClose(nil)
    }

    private init(service: any StenographerDaemonService) {
        super.init(windowID: "ai-log",
                   contentViewController: AILogViewController(service: service))
        self.windowTitle = "Stenographer — AI Log"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 940, height: 560),
            minSize: NSSize(width: 640, height: 360),
            defaultPosition: .center,
            persistsFrame: true
        )
    }
}
