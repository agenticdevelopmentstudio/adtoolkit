import AppKit

/// A flipped container view. Used as an `NSScrollView` document view so its
/// content anchors to the top-left: without this, a document shorter than the
/// clip view sinks to the bottom (AppKit's default bottom-up coordinates),
/// leaving an empty gap above the content when the window is taller than its
/// rows.
public final class TopAnchoredFlippedView: NSView {
    public override var isFlipped: Bool { true }
}
