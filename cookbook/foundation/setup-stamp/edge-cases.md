
- **Null / empty input**: An empty stamp file reads as an empty recorded version, which differs from any real bundle version, so setup is needed; recording an empty version string writes an empty file.
- **Boundary values**: The comparison is exact string equality after trimming, so `1.2.3` and `1.2.3.0` differ.
- **Concurrent access**: The write is atomic, so a concurrent reader sees the old or the new stamp, never a partial one; two simultaneous recorders are last-writer-wins.
- **Error states**: Reading never throws; any read failure means setup is needed. Recording throws on any filesystem failure.
- **Offline / disconnected state**: Not applicable: The stamp has no network access.
- **Cancellation**: Not applicable: The stamp has no concern of this kind beyond what Behavioral Requirements state.

