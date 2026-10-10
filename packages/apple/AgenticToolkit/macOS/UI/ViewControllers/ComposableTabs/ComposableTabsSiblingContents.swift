import AppKit

extension NSViewController {

    /// The content of every pane in this view controller's tab, in reading
    /// order, its own pane's included — empty when it is not inside a pane.
    ///
    /// Reached by walking up to the pane holding this view controller and from
    /// there to the tab's root split, so it answers for whatever the layout is
    /// *now*: a pane added or closed since the last call is counted or not.
    public func tabPaneContents() -> [NSViewController] {
        var ancestor = parent
        while let current = ancestor, !(current is ComposableTabsPaneViewController) {
            ancestor = current.parent
        }
        guard let pane = ancestor as? ComposableTabsPaneViewController,
              let split = pane.host as? ComposableTabsViewController,
              let root = split.rootSplit() else { return [] }
        return root.allLeaves().compactMap(\.contentViewController)
    }
}
