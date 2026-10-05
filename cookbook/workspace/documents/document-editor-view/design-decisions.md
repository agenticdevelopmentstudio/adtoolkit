
**Decision**: `show(_:persist:)` determines whether a URL is a directory by asking `url.resourceValues(forKeys: [.isDirectoryKey])` rather than assuming every URL it is given names a file.
**Rationale**: Every caller hands over a bare URL — a restored path, a breadcrumb choice, a go-to-definition target, the file tree's own open request — and a directory is among the things they can legitimately name; asserting it was always a file previously let `FileEditorView.openableNode` read a directory off disk.
**Approved**: pending

**Decision**: The gear popover's row references (`lineNumbersRow`, `overviewRow`, `invisiblesRow`, `resetRow`) are held `weak` and individually, not as a strong array.
**Rationale**: The options dialog owns its views and takes them with it when it closes; holding them weakly lets the references go `nil` on their own rather than keeping a dismissed dialog's checkboxes alive to be written to by a later `refreshOptionRows()` call.
**Approved**: pending

**Decision**: Restoring a stored file during initialization calls `show(url, persist: false)`, while `fileURL`'s setter and `clearDocument()` call `show(_, persist: true)`.
**Rationale**: A value just read from the store does not need to be written straight back to it; only a change made after construction needs to be persisted.
**Approved**: pending

**Decision**: `EditorOptionsOverride` resolves each of its three options independently, on every read (`stored.showLineNumbers ?? UserSettings.editorShowLineNumbers.value`), rather than this controller snapshotting the resolved values once.
**Rationale**: An editor pane must keep following the app-wide setting for any option it has not itself overridden, so that overriding "line numbers" in one pane never silently pins "overview" or "invisibles" in that same pane, and so a later app-wide change still reaches a pane that has not overridden that option.
**Approved**: pending

