
- **Data collected**: None of its own. The view displays file metadata (name, path, size, modification date, type, child count) already resolved onto the `FileTreeNode` it is given; it reads and collects nothing itself.
- **Storage**: Not applicable — the view persists nothing; every displayed value is recomputed from `selectedNode` and `config` on each render and held only in memory for that render.
- **Transmission**: Not applicable — the view performs no networking and sends nothing anywhere.
- **Retention**: Not applicable — no data is retained beyond the current `selectedNode`'s in-memory properties.

