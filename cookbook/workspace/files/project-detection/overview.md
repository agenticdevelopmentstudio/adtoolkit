
Two logic components in the file browser's detection model, neither with a
visual surface of its own, that inspect the local file system on behalf of
the file browser: an IDE/tool-marker detector that scans a project root for
IDE/tool project markers (`.xcodeproj`, `.xcworkspace`, `Package.swift`,
`.vscode`, `.idea`) up to one directory level deep and publishes the sorted,
deduplicated result on the UI thread; and a language-detection component, a
stateless set of functions that resolves a file URL to a code-language
value — consulting the user's own extension overrides before the built-in
table — and separately remaps that language to the identifier the Language
Server Protocol expects. The IDE/tool-marker detector is consumed today by
the file tree's root manager (one instance per project root); the
language-detection component is consumed by the file editor's state and is
the toolkit's one place that derives an LSP `languageId` from a
code-language value.

