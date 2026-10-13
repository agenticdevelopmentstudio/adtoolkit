//
//  BrowserDrivenBadge.swift
//  AgenticToolkit
//

import AppKit

/// A `sparkles` symbol at the end of the address bar, shown while a model
/// drives the pane and for two seconds after it stops, so a single quick
/// action is still noticed. The user keeps the pane: nothing here blocks a
/// click or a keystroke.
@MainActor
public final class BrowserDrivenBadge: NSView {

    /// How long the badge stays after the last action ends.
    public static let hold: TimeInterval = 2

    private static let explanation = "A model is driving this pane"

    private let symbol = NSImageView()
    private var hideWork: DispatchWorkItem?

    public private(set) var isShowing = false

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
        symbol.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: Self.explanation)
        symbol.contentTintColor = .controlAccentColor
        symbol.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: 18),
            heightAnchor.constraint(equalToConstant: 18)
        ])
        toolTip = Self.explanation
        setAccessibilityIdentifier("browser.driven")
        setAccessibilityLabel(Self.explanation)
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// `true` shows the badge at once; `false` keeps it for `hold` seconds
    /// and then hides it, unless another action starts in between.
    public func setDriven(_ driven: Bool) {
        hideWork?.cancel()
        hideWork = nil
        if driven {
            isShowing = true
            isHidden = false
            return
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isShowing = false
            self.isHidden = true
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hold, execute: work)
    }
}
