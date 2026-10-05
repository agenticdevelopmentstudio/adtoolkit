
This component renders the one screen a `vscode.window.showQuickPick` call
needs: a search field that filters a list of rows, where each row is either
a selectable item (with an optional leading checkbox for multi-select) or a
non-selectable separator/heading. It is built from an
`ExtensionQuickPickModel` (supplied at construction, framework-free) that
owns the filter query, the visible row order, the highlighted row, and — in
multi-select — the checked set. The component reports its outcome through
three callbacks: `onAccept` (the chosen indices), `onCancel` (dismissal), and
`onHighlight` (the highlighted row changed). It is modelled directly on the
sibling command-palette view and shares its keyboard-routing component with
four other pickers in the same module.

