
- **Data collected**: This component displays whatever tree item fields (label, description, tooltip, symbol name) and tree chrome (title, message) the extension's own data source supplies, and forwards the user's selection, expansion, and activation back to that same data source. It introduces no data collection of its own beyond that pass-through.
- **Storage**: None persistent. The row cache and all loading/stale-handle bookkeeping are in-memory only and are discarded with the pane.
- **Transmission**: None directly. No network call appears anywhere in this component; whatever the extension's own provider implementation does over a network, if anything, is outside this recipe's scope.
- **Retention**: Tied to the pane's lifetime — the in-memory table and bookkeeping are released when the pane (or its tree component) is torn down; nothing here persists across launches.

