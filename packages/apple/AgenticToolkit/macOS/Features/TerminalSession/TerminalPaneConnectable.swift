import AppKit

/// Pane content holding a terminal that something else in the window — a
/// Terminal Chat — can connect to and type into.
///
/// All a connecting pane learns is the session: whether that terminal is an
/// ordinary one or a private one is the terminal pane's business, and what it
/// does to the text on the way in and out happens inside the session.
@MainActor
public protocol TerminalPaneConnectable: AnyObject {
    /// The terminal a connection would type into, or nil when there is none
    /// to offer right now.
    var connectableTerminal: TerminalSession? { get }
}

extension TerminalSessionContentViewController: TerminalPaneConnectable {
    public var connectableTerminal: TerminalSession? { sessionManager.selectedSession }
}
