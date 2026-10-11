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

    /// The terminal a connection types into, started first if it has not
    /// started yet — a connection is a reason to start, as appearing is. Nil
    /// when it cannot be.
    func startConnectableTerminal() async throws -> TerminalSession?
}

extension TerminalPaneConnectable {
    /// A terminal that is running as soon as it exists has nothing to start.
    public func startConnectableTerminal() async throws -> TerminalSession? { connectableTerminal }
}

extension Notification.Name {
    /// Posted, with the pane content as the object, when a
    /// ``TerminalPaneConnectable``'s ``TerminalPaneConnectable/connectableTerminal``
    /// changes — a terminal that starts after its pane appeared, say — so a
    /// chat waiting on that pane can connect.
    public static let terminalPaneConnectableDidChange = Notification.Name("TerminalPaneConnectableDidChange")
}

extension TerminalSessionContentViewController: TerminalPaneConnectable {
    public var connectableTerminal: TerminalSession? { sessionManager.selectedSession }
}
