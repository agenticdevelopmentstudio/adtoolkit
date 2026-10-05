
- **notes-storage-failure-titles**: A storage failure's operation titles
  are four hardcoded English literals — "Couldn't Load Notes", "Couldn't
  Create Note", "Couldn't Save Note", "Couldn't Delete Note" — with no
  localization mechanism wrapping any of them; a caller presenting the
  storage failure sees exactly this English text.
- **notes-storage-failure-consequences**: A storage failure's operation
  consequences likewise are four hardcoded English sentences describing
  what the failure means for what is on screen; the delete case
  interpolates a separately-localized product/location name into an
  otherwise unlocalized English sentence.
- **notes-storage-failure-message-passthrough**: A storage failure's
  message is the underlying error's own localized description, shown
  verbatim; whatever localization that error itself carries, or lacks,
  passes through this layer unchanged — the markdown-backed conformer and
  the manager neither translate nor re-wrap it.

