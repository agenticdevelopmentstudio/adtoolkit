
- **Data collected**: Only this pane's own chrome state — minimize edge, zoomed flag, and spacing override — written through the injected state store. No personal or otherwise sensitive data is read or written by this concept.
- **Storage**: Whatever the injected state store implements. The ephemeral default keeps values in memory only, for exactly as long as the pane exists. A persistent store is the caller's own choice and out of this recipe's scope.
- **Transmission**: None. No network call appears anywhere in this concept.
- **Retention**: Governed entirely by whichever state store is injected; the pane defines no retention policy of its own.

