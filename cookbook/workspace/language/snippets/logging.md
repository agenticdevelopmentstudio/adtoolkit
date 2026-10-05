
Not applicable: none of `ExtensionSnippet.swift`, `SnippetFile.swift`, or `SnippetStore.swift` calls `os_log`, `Logger`, or `print`. Parse and read failures are recorded into `SnippetStore.failures` for the extensions settings panel to display, not written to a log.

