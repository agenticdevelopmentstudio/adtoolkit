
- **Data collected**: The host reads the extension's own bundled JavaScript entry point off disk and runs it; the ledger records extension-authored identifiers and API member-path strings an extension reached for. None of the three roles reads or transmits a credential, token, or other secret value of its own.
- **Extension-authored content is privacy-annotated, not filtered**: Every logged interpolation of extension-controlled text — `console.*` output, an extension identifier, a thrown exception's message and stack, a define-vscode-member origin, a member path recorded in the ledger — is deliberately marked public in the host's and installer's own logging calls, rather than redacted. This is a deliberate choice to keep extension diagnostics readable in the system log, not an oversight; it means an extension author's own file contents, console output, and error text are treated as debuggable diagnostic data, not as a secret the host must protect.
- **Storage**: The ledger's entries and the host's own runtime state are in-memory only for the life of the process; nothing in these three roles persists an entry to disk.
- **Transmission**: Not applicable — none of the three roles performs networking.
- **Retention**: A ledger entry lives for the life of the ledger instance (typically the app process); the host's and an installation's state is released on dispose.

