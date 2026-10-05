
This component is the detail pane of a file browser: it renders a placeholder message when nothing is selected, and a non-scrolling metadata sheet — icon, name, type, full path, size, modification date, and item count — when a `FileTreeNode` is selected. It performs no filesystem access of its own; every value it shows was already computed onto the `FileTreeNode` (or, for package display names, supplied by the caller's `FileTreeConfig`) before this component ever sees it. The component is a pure function of its two inputs (`selectedNode`, `config`); it holds no state of its own.

