
Not applicable — this is a script-engine bridge and in-memory store, not a visual component. Its only lifecycle-shaped behavior is per-collection disposal (inert-but-not-thrown once its disposal flag is set) and adaptor-level disposal, both captured under Behavioral Requirements rather than as a visual-state table.

