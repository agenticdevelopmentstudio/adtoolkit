
Document text, completion prefixes, and hover/diagnostic content pass through this family only in memory, addressed to the language server already configured for that document's project; none of these twelve components persists, logs, or forwards document content to any destination other than that server. The document coordinator's unsaved-documents log message names document identifiers, not their content.

