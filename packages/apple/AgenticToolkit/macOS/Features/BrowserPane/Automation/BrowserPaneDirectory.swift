import Foundation

/// One Browser pane as the tool set sees it. Title and URL are read live
/// from `automation`, so a handle never goes stale on its own.
@MainActor
public struct BrowserPaneHandle {
    public let id: String
    public let project: String
    public let tab: String
    public let automation: BrowserAutomation

    public init(id: String, project: String, tab: String, automation: BrowserAutomation) {
        self.id = id; self.project = project; self.tab = tab; self.automation = automation
    }

    public var title: String { automation.currentTitle }
    public var url: String { automation.currentURL }
}

/// How the tool set finds Browser panes. The app supplies the real one over
/// its windows; tests supply a fake.
@MainActor
public protocol BrowserPaneDirectory: AnyObject {
    /// Every open Browser pane, front window first.
    func browserPanes() -> [BrowserPaneHandle]
    func browserPane(id: String) -> BrowserPaneHandle?
    /// A Browser pane in the same tab as the pane with this node id.
    func browserPane(besidePane paneID: String) -> BrowserPaneHandle?
    /// The Browser pane most recently active, if still open.
    func lastUsedBrowserPane() -> BrowserPaneHandle?
    /// Opens a Browser pane beside the caller's pane (or in the front
    /// window when nil / unknown) and returns it.
    func openBrowserPane(besidePane paneID: String?) throws -> BrowserPaneHandle
}
