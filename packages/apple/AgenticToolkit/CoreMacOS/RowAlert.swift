import AppKit

/// Runs an `NSAlert` with its buttons in one horizontal row, as macOS alerts
/// lay them out.
///
/// `NSAlert` on macOS 26 stacks three or more buttons vertically, whatever its
/// accessory view, width or presentation. Up to two buttons it already uses a
/// row, so it runs as itself; from three on, ``RowAlertPanel`` shows the same
/// alert — message, informative text, icon and buttons — in a row.
@MainActor
public enum RowAlert {
    public static func usesPanel(for alert: NSAlert) -> Bool { alert.buttons.count > 2 }

    /// Answers exactly as `NSAlert.runModal()` would: `alertFirstButtonReturn`
    /// for the first button added, and so on in the order they were added.
    public static func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse {
        guard usesPanel(for: alert) else { return alert.runModal() }
        return RowAlertPanel(alert).runModal()
    }
}

/// The row layout of a three-or-more-button alert, the traditional macOS
/// arrangement (Cancel … Skip Remove):
///
/// - a button whose key equivalent is Escape (else one titled "Cancel") goes
///   alone at the far left and answers Escape;
/// - the others sit together on the right, the first (the default, answering
///   Return) rightmost and each later one to the left of the one before.
///
/// Each button keeps its key equivalent, modifier mask and tag. Only the
/// alert's text, icon and buttons are shown; it has no accessory view or
/// suppression button.
@MainActor
public final class RowAlertPanel: NSObject {
    public let window: NSPanel
    /// The buttons in the alert's order. A click answers the button's tag when
    /// it is nonzero, else `alertFirstButtonReturn + i` for index `i`.
    public let buttons: [NSButton]
    /// How a click ends the alert. Tests replace it; live it stops the modal.
    var respond: (NSApplication.ModalResponse) -> Void = { NSApp.stopModal(withCode: $0) }

    private static let textWidth: CGFloat = 340
    private static let minimumButtonWidth: CGFloat = 82

    public init(_ alert: NSAlert) {
        buttons = alert.buttons.map { NSButton(title: $0.title, target: nil, action: nil) }
        window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 460, height: 160),
                         styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        super.init()

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.hidesOnDeactivate = false

        let icon = NSImageView(image: alert.icon ?? NSApp.applicationIconImage ?? NSImage())
        icon.translatesAutoresizingMaskIntoConstraints = false

        let message = NSTextField(wrappingLabelWithString: alert.messageText)
        message.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        message.isSelectable = false
        let informative = NSTextField(wrappingLabelWithString: alert.informativeText)
        informative.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        informative.isSelectable = false
        informative.isHidden = alert.informativeText.isEmpty
        for label in [message, informative] {
            label.preferredMaxLayoutWidth = Self.textWidth
            label.widthAnchor.constraint(equalToConstant: Self.textWidth).isActive = true
        }
        let text = NSStackView(views: [message, informative])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 8

        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 12
        // Escape answers the button that already claims it, else "Cancel".
        let escapeKey = "\u{1b}"
        let escapeIndex = alert.buttons.firstIndex { $0.keyEquivalent == escapeKey }
            ?? alert.buttons.firstIndex { $0.title == "Cancel" }
        for (index, button) in buttons.enumerated() {
            let source = alert.buttons[index]
            button.bezelStyle = .push
            button.keyEquivalent = source.keyEquivalent
            button.keyEquivalentModifierMask = source.keyEquivalentModifierMask
            button.tag = source.tag
            button.target = self
            button.action = #selector(clicked(_:))
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumButtonWidth).isActive = true
        }
        if let escapeIndex {
            buttons[escapeIndex].keyEquivalent = escapeKey
            row.addView(buttons[escapeIndex], in: .leading)
        }
        // Trailing views lay out left to right, so the last-added button goes
        // in first and the default ends up rightmost.
        for (index, button) in buttons.enumerated().reversed() where index != escapeIndex {
            row.addView(button, in: .trailing)
        }
        // NSAlert already marks its first button as the default; only fill in
        // Return when nothing the alert gave us claims it.
        if let first = buttons.first, !buttons.contains(where: { $0.keyEquivalent == "\r" }),
           first.keyEquivalent.isEmpty {
            first.keyEquivalent = "\r"
        }

        let column = NSStackView(views: [text, row])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 20
        column.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalTo: text.widthAnchor).isActive = true

        let content = NSView()
        content.addSubview(icon)
        content.addSubview(column)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 64),
            icon.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            icon.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            column.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            column.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            column.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            column.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            content.bottomAnchor.constraint(greaterThanOrEqualTo: icon.bottomAnchor, constant: 20)
        ])
        window.contentView = content
        content.layoutSubtreeIfNeeded()
        window.setContentSize(content.fittingSize)
    }

    public func runModal() -> NSApplication.ModalResponse {
        window.center()
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil) }
        return NSApp.runModal(for: window)
    }

    @objc private func clicked(_ sender: NSButton) {
        respond(Self.response(forTag: sender.tag, at: buttons.firstIndex(of: sender) ?? 0))
    }

    /// A button's own tag when it set one, else its position in the alert.
    static func response(forTag tag: Int, at index: Int) -> NSApplication.ModalResponse {
        NSApplication.ModalResponse(
            rawValue: tag != 0 ? tag : NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + index)
    }
}
